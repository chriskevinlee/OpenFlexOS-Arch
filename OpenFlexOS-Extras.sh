#!/usr/bin/env bash
# OpenFlexOS Arch Linux package installer
set -o pipefail

BUILD_USER="_aurbuilder"
BUILD_HOME="/var/tmp/${BUILD_USER}-home"
AUR_BUILD_BASE="/var/tmp/openflexos-aur"
CREATED_BUILD_USER=0
CREATED_SUDOERS=0

msg() { printf '\n[+] %s\n' "$*"; }
err() { printf '\n[-] %s\n' "$*" >&2; }
pause() { read -r -p 'Press Enter to return to the menu...' _ || true; }

# This installer uses sudo for privileged operations and runs makepkg unprivileged.
if (( EUID == 0 )); then
    echo 'Please run this script as your normal user (with sudo access), not root.' >&2
    exit 1
fi
if ! command -v sudo >/dev/null || ! command -v pacman >/dev/null; then
    err 'This installer requires Arch Linux, pacman and sudo.'
    exit 1
fi

ensure_aur_builder() {
    msg 'Installing AUR build prerequisites'
    sudo pacman -S --needed --noconfirm git base-devel sudo || return 1

    if ! id "$BUILD_USER" &>/dev/null; then
        msg "Creating temporary user $BUILD_USER"
        sudo useradd --system --home-dir "$BUILD_HOME" --shell /bin/bash "$BUILD_USER" || return 1
        CREATED_BUILD_USER=1
    fi

    local build_group
    build_group="$(id -gn "$BUILD_USER")" || return 1
    sudo install -d -m 700 -o "$BUILD_USER" -g "$build_group" "$BUILD_HOME" "$AUR_BUILD_BASE" || return 1

    # makepkg -s needs pacman to install build dependencies. This sudoers rule
    # is temporary but grants broad pacman access: only build trusted PKGBUILDs.
    if [[ ! -e "/etc/sudoers.d/$BUILD_USER" ]]; then
        printf '%s ALL=(root) NOPASSWD: /usr/bin/pacman\n' "$BUILD_USER" | \
            sudo tee "/etc/sudoers.d/$BUILD_USER" >/dev/null || return 1
        sudo chmod 440 "/etc/sudoers.d/$BUILD_USER" || return 1
        CREATED_SUDOERS=1
    fi
}

build_aur_pkg() {
    local pkg="$1"; shift
    local build_dir="$AUR_BUILD_BASE/${pkg}-build"
    local -a pkgfiles=()
    local -a makepkg_options=(--noconfirm)
    if (( $# > 0 )); then makepkg_options+=("$@"); fi

    msg "Building AUR package: $pkg"
    sudo rm -rf -- "$build_dir" || return 1
    local build_group
    build_group="$(id -gn "$BUILD_USER")" || return 1
    sudo install -d -m 700 -o "$BUILD_USER" -g "$build_group" "$build_dir" || return 1

    # Source and build output remain on disk rather than RAM-backed /tmp.
    if ! sudo -u "$BUILD_USER" env HOME="$BUILD_HOME" TMPDIR="$build_dir" \
        bash -c '
            set -e
            build_dir="$1"; pkg="$2"; shift 2
            cd "$build_dir"
            git clone -- "https://aur.archlinux.org/${pkg}.git" .
            makepkg -s "$@"
        ' _ "$build_dir" "$pkg" "${makepkg_options[@]}"; then
        err "Build failed: $pkg"
        return 1
    fi

    # Package filenames may contain whitespace; exclude debug split packages.
    mapfile -d '' -t pkgfiles < <(
        sudo -u "$BUILD_USER" find "$build_dir" -maxdepth 1 -type f -name '*.pkg.tar.*' \
            ! -name '*-debug-*.pkg.tar.*' -print0
    )
    if (( ${#pkgfiles[@]} == 0 )); then
        err "No built package files found for $pkg"
        return 1
    fi
    sudo pacman -U --noconfirm -- "${pkgfiles[@]}"
}

cleanup_aur_builder() {
    msg 'Cleaning up AUR build files'
    sudo rm -rf -- "$AUR_BUILD_BASE" "$BUILD_HOME" || return 1
    # Do not remove pre-existing accounts or sudoers rules we did not create.
    if (( CREATED_SUDOERS )); then
        sudo rm -f -- "/etc/sudoers.d/$BUILD_USER" || return 1
        CREATED_SUDOERS=0
    fi
    if (( CREATED_BUILD_USER )); then
        sudo userdel "$BUILD_USER" || return 1
        CREATED_BUILD_USER=0
    fi
}

# Bootstrap yay with the existing unprivileged AUR build mechanism.
# Thereafter yay resolves both repository and AUR dependencies as the real user.
ensure_yay() {
    if command -v yay >/dev/null 2>&1; then
        return 0
    fi

    msg "Bootstrapping yay for automatic AUR dependency resolution"
    local result=0
    if ensure_aur_builder; then
        build_aur_pkg yay || result=1
        cleanup_aur_builder || result=1
    else
        result=1
        cleanup_aur_builder || true
    fi
    (( result == 0 )) && command -v yay >/dev/null 2>&1
}

install_aur() {
    (( $# > 0 )) || return 0
    ensure_yay || { err "Unable to install yay"; return 1; }

    msg "Installing AUR package(s) with dependency resolution: $*"
    # yay must run as the invoking user, not root.
    # Let users review PKGBUILDs; do not disable source-integrity checks.
    yay -S --needed --noconfirm "$@"
}

install_repo() {
    sudo pacman -S --needed --noconfirm "$@"
}

# Use DKMS with headers for every detected official Arch kernel.
install_virtualbox() {
    local kernel
    local -a kernels=() packages=(virtualbox virtualbox-host-dkms dkms)

    for kernel in linux linux-lts linux-zen linux-hardened; do
        if pacman -Qq "$kernel" &>/dev/null; then
            kernels+=("$kernel")
            packages+=("${kernel}-headers")
        fi
    done

    if (( ${#kernels[@]} == 0 )); then
        err 'No supported official Arch kernel package found.'
        err 'Custom kernels require matching headers for virtualbox-host-dkms.'
        return 1
    fi

    msg "Detected installed kernels: ${kernels[*]}"
    msg 'Installing VirtualBox, DKMS, and kernel headers'
    install_repo "${packages[@]}" || return 1

    # Load VirtualBox's VM, bridged, and host-only networking modules now.
    # Also configure systemd to load them on subsequent boots.
    local module
    local module_failed=0
    local -a vbox_modules=(vboxdrv vboxnetflt vboxnetadp)

    msg 'Configuring VirtualBox modules to load at boot'
    if ! printf '%s\n' "${vbox_modules[@]}" | \
        sudo tee /etc/modules-load.d/virtualbox.conf >/dev/null; then
        err 'Could not configure VirtualBox modules for automatic loading.'
        return 1
    fi

    for module in "${vbox_modules[@]}"; do
        if sudo modprobe "$module"; then
            msg "Loaded module: $module"
        else
            err "Could not load module: $module"
            module_failed=1
        fi
    done

    if (( module_failed )); then
        err 'VirtualBox installed, but one or more modules could not be loaded.'
        err 'If the kernel was updated, reboot and try again.'
        err 'Otherwise check: dkms status, matching headers, and Secure Boot.'
        return 1
    fi
    msg 'VirtualBox and networking modules are ready.'

}

configure_nomachine() {
    local cfg='/usr/NX/etc/server.cfg'
    if [[ ! -f "$cfg" ]]; then
        err "NoMachine configuration not found: $cfg"
        return 1
    fi
    if ! grep -q '^# Enforced by install script' "$cfg"; then
        sudo cp -p -- "$cfg" "${cfg}.bak" || return 1
        local tmpfile
        tmpfile="$(mktemp /var/tmp/openflexos-nxcfg.XXXXXX)" || return 1
        printf '%s\n' \
            '# Enforced by install script' \
            'EnableHardwareAcceleration 1' \
            'PhysicalDisplays 1' \
            'EnableAutoResume 0' \
            'DisplayManagerLogin 1' \
            'CreateDisplay 0' > "$tmpfile"
        cat "${cfg}.bak" >> "$tmpfile" || { rm -f "$tmpfile"; return 1; }
        sudo install -m 644 "$tmpfile" "$cfg" || { rm -f "$tmpfile"; return 1; }
        rm -f "$tmpfile"
    fi

    msg 'Installing Qtile X11 session entry'
    sudo install -d /usr/share/xsessions || return 1
    printf '%s\n' \
        '[Desktop Entry]' \
        'Name=Qtile' \
        'Comment=Qtile Session' \
        'Exec=dbus-run-session qtile start' \
        'Type=Application' \
        'DesktopNames=qtile' | sudo tee /usr/share/xsessions/qtile.desktop >/dev/null || return 1

    msg 'Installing NoMachine launcher'
    sudo install -d /usr/share/applications || return 1
    printf '%s\n' \
        '[Desktop Entry]' \
        'Name=NoMachine' \
        'Comment=Connect to remote desktops' \
        'Exec=/usr/NX/bin/nxplayer' \
        'Icon=NoMachine' \
        'Terminal=false' \
        'Type=Application' \
        'Categories=Network;RemoteAccess;' \
        'StartupNotify=true' | sudo tee /usr/share/applications/nomachine.desktop >/dev/null || return 1

    msg 'Installing optional NoMachine startup unit'
    printf '%s\n' \
        '[Unit]' \
        'Description=NoMachine NX Server Startup' \
        'After=network.target' \
        '' \
        '[Service]' \
        'Type=oneshot' \
        'ExecStart=/usr/NX/bin/nxserver --startup' \
        'RemainAfterExit=yes' \
        '' \
        '[Install]' \
        'WantedBy=multi-user.target' | sudo tee /etc/systemd/system/nxserverstartup.service >/dev/null || return 1
    sudo systemctl daemon-reload || return 1

    echo 'NoMachine may listen on port 4000 and become accessible on your network.'
    local yn
    read -r -p 'Enable and start the custom NoMachine startup service? (y/N) ' yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        sudo systemctl enable --now nxserverstartup.service || return 1
    fi
}

# Special installers: use these only when an app needs additional setup.
install_anydesk() {
    install_aur yp-tools anydesk-bin || return 1
    local yn
    read -r -p 'Enable and start AnyDesk service? (y/N) ' yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        sudo systemctl enable --now anydesk || return 1
    fi
    return 0
}

install_nomachine() {
    install_aur nomachine && configure_nomachine
}

install_handy() {
    install_repo python-huggingface-hub || return 1
    install_aur handy-bin || return 1
    msg 'Downloading Handy Parakeet TDT-CTC 110M model'
    hf download handy-computer/parakeet-tdt_ctc-110m-gguf \
        parakeet-tdt_ctc-110m-Q8_0.gguf \
        --cache-dir "$HOME/.cache/huggingface/hub"
}

# Application registry: menu labels, installed checks and commands share one entry.
# The first package for add_repo/add_aur is used for the Installed label.
declare -a packages=()
declare -A app_index=() app_primary=()

add_app() {
    local label="$1" primary="$2"
    shift 2
    local index=${#packages[@]}
    packages+=("$label")
    app_index["$label"]=$index
    app_primary["$label"]=$primary
    # Preserve each command argument separately; no eval or shell splitting.
    declare -g -a "app_command_$index"
    local -n command_ref="app_command_$index"
    command_ref=("$@")
}

add_repo() {
    local label="$1"; shift
    add_app "$label" "$1" install_repo "$@"
}

add_aur() {
    local label="$1"; shift
    add_app "$label" "$1" install_aur "$@"
}

# ============================================================
# ADD OR REMOVE APPLICATIONS HERE
# add_repo 'Display name' package [additional packages...]
# add_aur  'Display name(AUR)' package [additional packages...]
# add_app  'Display name' primary-package custom_install_function
# ============================================================
add_app  'VirtualBox' virtualbox install_virtualbox
add_repo 'VLC' vlc
add_repo 'FileZilla' filezilla
add_repo 'GIMP' gimp
add_repo 'Gparted' gparted ntfs-3g dosfstools exfatprogs btrfs-progs \
    xfsprogs f2fs-tools jfsutils nilfs-utils udftools mtools \
    e2fsprogs bcachefs-tools
add_repo 'qBittorrent' qbittorrent
add_repo 'Audacity' audacity
add_repo 'Obsidian' obsidian
add_repo 'KDE ISO Image Writer' isoimagewriter
add_aur  'Brave(AUR)' brave-bin
add_app  'AnyDesk(AUR)' anydesk-bin install_anydesk
add_app  'NoMachine(AUR)' nomachine install_nomachine
add_aur  'Sublime-Text(AUR)' sublime-text-4
add_aur  'yay(AUR)' yay
add_aur  'WoeUSB(AUR)' woeusb-ng
add_aur  'KDocker(AUR)' kdocker
add_aur  'LocalSend(AUR)' localsend-bin
add_app  'Handy(AUR)' handy-bin install_handy

# These options are always appended automatically.
packages+=('Install All' 'Exit')
INSTALL_ALL_NUMBER=$((${#packages[@]} - 1))

install_selected_app() {
    local app="$1" result=0
    local -n command_ref="app_command_${app_index[$app]}"
    "${command_ref[@]}" || result=1
    if (( result == 0 )); then
        msg "$app completed successfully"
    else
        err "$app failed; review the messages above"
    fi
    return "$result"
}

# The Installed label refers to the primary application package only.
is_app_installed() {
    local pkg="${app_primary[$1]:-}"
    [[ -n "$pkg" ]] && pacman -Qq -- "$pkg" &>/dev/null
}

while true; do
    printf '\n=== OpenFlexOS Package Installer ===\n'
    for (( i=0; i<${#packages[@]}; i++ )); do
        if is_app_installed "${packages[i]}"; then
            printf '%2d) %s (Installed)\n' "$((i+1))" "${packages[i]}"
        else
            printf '%2d) %s\n' "$((i+1))" "${packages[i]}"
        fi
    done
    printf '\nEnter numbers separated by commas or spaces; use %d -4 -7 to exclude packages from Install All.\n' "$INSTALL_ALL_NUMBER"
    if ! read -r -p 'Selection: ' selection; then
        printf '\n'
        break
    fi

    # Accept commas and/or spaces, keeping the user's requested order.
    selection="${selection//,/ }"
    read -r -a choices <<< "$selection"
    (( ${#choices[@]} > 0 )) || { err 'Enter at least one option.'; continue; }

    selected_apps=()
    valid=1
    install_all=0
    exit_selected=0
    excluded_numbers=()

    for choice in "${choices[@]}"; do
        if [[ "${choice,,}" == all ]]; then
            choice=$INSTALL_ALL_NUMBER
        fi
        if [[ "$choice" =~ ^-([0-9]{1,6})$ ]]; then
            number=$((10#${BASH_REMATCH[1]}))
            if (( number < 1 || number > ${#packages[@]}-2 )); then
                err "Invalid exclusion: $choice"
                valid=0
                break
            fi
            excluded_numbers+=("$number")
            continue
        fi
        if [[ ! "$choice" =~ ^[0-9]{1,6}$ ]]; then
            err "Invalid selection: $choice"
            valid=0
            break
        fi
        number=$((10#$choice))
        if (( number < 1 || number > ${#packages[@]} )); then
            err "Invalid selection: $choice"
            valid=0
            break
        fi
        case "${packages[number-1]}" in
            'Install All') install_all=1 ;;
            'Exit') exit_selected=1 ;;
            *) selected_apps+=("${packages[number-1]}") ;;
        esac
    done
    (( valid )) || continue

    if (( exit_selected )); then
        if (( ${#choices[@]} != 1 )); then
            err 'Exit must be selected on its own.'
            continue
        fi
        break
    fi
    if (( install_all )); then
        if (( ${#selected_apps[@]} > 0 )); then
            err 'Install All cannot be combined with individual package selections; use -N to exclude packages.'
            continue
        fi
        selected_apps=()
        for (( i=1; i<=${#packages[@]}-2; i++ )); do
            skip=0
            for number in "${excluded_numbers[@]}"; do
                if (( i == number )); then
                    skip=1
                    break
                fi
            done
            (( skip )) || selected_apps+=("${packages[i-1]}")
        done
    elif (( ${#excluded_numbers[@]} > 0 )); then
        err "Exclusions (-N) require Install All ($INSTALL_ALL_NUMBER or all)."
        continue
    fi

    failures=0
    for app in "${selected_apps[@]}"; do
        msg "Starting: $app"
        install_selected_app "$app" || ((failures+=1))
    done
    if (( failures > 0 )); then
        err "$failures installation(s) failed."
    fi
    pause
done

echo 'Exiting OpenFlexOS package installer.'
