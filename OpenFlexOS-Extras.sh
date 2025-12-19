clear
# -------------------- AUR BUILDER COMMON SETUP --------------------
BUILD_USER=_aurbuilder
BUILD_HOME=/tmp/${BUILD_USER}-home

ensure_aur_builder() {
    sudo pacman -Sy --noconfirm --needed git base-devel

    if ! id "$BUILD_USER" &>/dev/null; then
        echo "[+] Creating AUR build user"
        sudo useradd -r -m -d "$BUILD_HOME" -s /bin/bash "$BUILD_USER"
    fi

    if [[ ! -f /etc/sudoers.d/$BUILD_USER ]]; then
        echo "[+] Allowing $BUILD_USER to use pacman"
        echo "$BUILD_USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" \
            | sudo tee /etc/sudoers.d/$BUILD_USER > /dev/null
        sudo chmod 440 /etc/sudoers.d/$BUILD_USER
    fi
}

build_aur_pkg() {
    local PKG="$1"
    local MAKEPKG_OPTS="${2:---noconfirm --skippgpcheck}"
    local BUILD_DIR="/tmp/${PKG}-build"

    echo "[+] Building AUR package: $PKG"

    sudo rm -rf "$BUILD_DIR"
    sudo mkdir -p "$BUILD_DIR"
    sudo chown -R "$BUILD_USER:$BUILD_USER" "$BUILD_DIR" "$BUILD_HOME"

    sudo -u "$BUILD_USER" env HOME="$BUILD_HOME" bash <<EOF
set -e
cd "$BUILD_DIR"
git clone https://aur.archlinux.org/${PKG}.git .
makepkg -s $MAKEPKG_OPTS
EOF

    # ✅ install all non-debug split packages
    PKGFILES=$(find "$BUILD_DIR" -maxdepth 1 -name "*.pkg.tar.*" ! -name "*-debug-*" | sort -V)

    if [[ -z "$PKGFILES" ]]; then
        echo "[-] Failed to build $PKG"
        exit 1
    fi

    sudo pacman -U --noconfirm $PKGFILES
}

cleanup_aur_builder() {
    echo "[+] Cleaning up AUR build user"
    sudo rm -rf /tmp/*-build "$BUILD_HOME"
    sudo rm -f /etc/sudoers.d/$BUILD_USER
    sudo userdel -r "$BUILD_USER" 2>/dev/null || true
}


packages=("VirtualBox" "VLC" "FileZilla" "GIMP" "Gparted" "KDE Connect" "qBittorrent" "Audacity" "Obsidian" "Brave(AUR)" "AnyDesk(AUR)" "NoMachine(AUR)" "Sublime-Text(AUR)")
PS3="Please choose an option (1-${#packages[@]}): "
echo "Please Choose a package to install"

select app in "${packages[@]}"; do
    case "$app" in
        "VirtualBox")
        sudo pacman -S --noconfirm virtualbox
        clear
            ;;
        "VLC")
        sudo pacman -S --noconfirm vlc
        clear
            ;;
        "FileZilla")
        sudo pacman -S --noconfirm filezilla
        clear
            ;;
        "GIMP")
        sudo pacman -S --noconfirm gimp
        clear
            ;;
        "Gparted")
        sudo pacman -S --noconfirm gparted
        ;;
        "KDE Connect")
        sudo pacman -S --noconfirm kdeconnect
        clear
        ;;
        "qBittorrent")
        sudo pacman -S --noconfirm qbittorrent
        clear
        ;;
        "Audacity")
        sudo pacman -S --noconfirm audacity
	clear
            ;;
        "Obsidian")
        sudo pacman -S --noconfirm obsidian
	clear
            ;;

        "Brave(AUR)")
        ensure_aur_builder
        build_aur_pkg brave-bin
        cleanup_aur_builder
        clear
        ;;
        "AnyDesk(AUR)")
        ensure_aur_builder
        build_aur_pkg yp-tools
        build_aur_pkg anydesk-bin
        cleanup_aur_builder
        clear

	read -p "Would you like to start and enable anydesk service?" yn
	
	if [[ $yn = y ]]; then
		sudo systemctl enable --now anydesk
	fi
    ;;
        "NoMachine(AUR)")
        ensure_aur_builder
        build_aur_pkg nomachine "--noconfirm"

        # ---- NoMachine config ----
        NXCFG="/usr/NX/etc/server.cfg"

        if ! grep -q '^# Enforced by install script' "$NXCFG"; then
            sudo cp "$NXCFG" "$NXCFG.bak"

            printf '%s\n' \
              '# Enforced by install script' \
              'EnableHardwareAcceleration 1' \
              'PhysicalDisplays 1' \
              'EnableAutoResume 0' \
              'DisplayManagerLogin 1' \
              'CreateDisplay 0' \
            | sudo tee /tmp/nxcfg.prepend > /dev/null

            sudo cat /tmp/nxcfg.prepend "$NXCFG.bak" | sudo tee "$NXCFG" > /dev/null
            sudo rm -f /tmp/nxcfg.prepend
        fi

            # ---------- Qtile session ----------
            echo "[+] Installing Qtile session"
            sudo mkdir -p /usr/share/xsessions
            printf '%s\n' \
              '[Desktop Entry]' \
              'Name=Qtile' \
              'Comment=Qtile Session' \
              'Exec=dbus-run-session qtile start' \
              'Type=Application' \
              'DesktopNames=qtile' \
            | sudo tee /usr/share/xsessions/qtile.desktop > /dev/null

            # ---------- NoMachine launcher ----------
            echo "[+] Installing NoMachine launcher"
            sudo mkdir -p /usr/share/applications
            printf '%s\n' \
              '[Desktop Entry]' \
              'Name=NoMachine' \
              'Comment=Connect to remote desktops' \
              'Exec=/usr/NX/bin/nxplayer' \
              'Icon=NoMachine' \
              'Terminal=false' \
              'Type=Application' \
              'Categories=Network;RemoteAccess;' \
              'StartupNotify=true' \
            | sudo tee /usr/share/applications/nomachine.desktop > /dev/null

            # ---------- systemd service ----------
            echo "[+] Installing nxserver startup service"
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
              'WantedBy=multi-user.target' \
            | sudo tee /etc/systemd/system/nxserverstartup.service > /dev/null

        sudo systemctl daemon-reload
        sudo systemctl enable --now nxserver.service

	clear
	echo "A systemd unit called nxserverstart.service has been added to allow NoMachine to use port 4000"
	echo "If nxserverstartup.service is started and enabled, this mahcine may be visable on the network"
	echo "If you select no you will need to either start this service with systemctl start nxserverstart"
	echo "or run /usr/NX/bin/nxserver --startup at a terminal or tty"
	read -p "Would you like to start and enable this service?" yn
	
	if [[ $yn = y ]]; then
		sudo systemctl enable --now nxserverstartup.service
	fi

        cleanup_aur_builder
        clear
        ;;
        "Sublime-Text(AUR)")
        ensure_aur_builder
        build_aur_pkg sublime-text-4
        cleanup_aur_builder
        clear
        ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
    REPLY=
    echo ""
    echo ">> Choose another option or exit:"
done
