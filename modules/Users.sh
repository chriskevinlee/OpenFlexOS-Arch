#!/bin/bash
clear

# -------------------------
# Select WM argument
# -------------------------
case "$1" in
    -Q) wm_dir="qtile" ;;
    -O) wm_dir="openbox" ;;
    *)
        echo "Usage: $0 -Q (for Qtile) or -O (for Openbox)"
        sleep 2
        exit 1
        ;;
esac

# -------------------------
# Base config directories
# -------------------------
config_dirs=(
    "$wm_dir"
    "alacritty"
    "dunst"
    "gtk-3.0"
    "gtk-4.0"
    "Kvantum"
    "MyThemes"
    "obmenu-generator"
    "ohmyposh"
    "picom"
    "qt5ct"
    "qt6ct"
    "wallpapers/wallpaper_cave_nature"
    "sxiv/exec"
    "web_bookmarks"
)

# WM-specific directories
if [[ $wm_dir == "openbox" ]]; then
    config_dirs+=(
        "$wm_dir/rofi"
        "$wm_dir/scripts"
        "$wm_dir/sounds"
        "$wm_dir/tint2"
    )
elif [[ $wm_dir == "qtile" ]]; then
    config_dirs+=(
        "$wm_dir/rofi"
        "$wm_dir/scripts/menu"
        "$wm_dir/sounds"
        "$wm_dir/systemd"
    )
fi

# -------------------------
# Prepare /etc/skel with dirs
# -------------------------
mkdir -p /etc/skel/.config
for dir in "${config_dirs[@]}"; do
    mkdir -p "/etc/skel/.config/$dir"
done

# -------------------------
# Populate /etc/skel with symlinks
# -------------------------
if [[ $wm_dir == "openbox" ]]; then

    # Main configs (ALL files)
    for openboxfile in /etc/openflexos/home/user/config/openbox/*; do
        ln -sf "$openboxfile" "/etc/skel/.config/openbox/$(basename "$openboxfile")"
    done

    # Scripts (ALL files)
    for openboxscripts in /etc/openflexos/usr/local/bin/*; do
        ln -sf "$openboxscripts" "/etc/skel/.config/openbox/scripts/$(basename "$openboxscripts")"
    done

    # Sounds (ALL files)
    for openboxsounds in /etc/openflexos/home/user/config/sounds/*; do
        ln -sf "$openboxsounds" "/etc/skel/.config/openbox/sounds/$(basename "$openboxsounds")"
    done

    # Tint2 (ALL files)
    for openboxtint2 in /etc/openflexos/home/user/config/openbox/tint2/*; do
        ln -sf "$openboxtint2" "/etc/skel/.config/openbox/tint2/$(basename "$openboxtint2")"
    done

    # Rofi (ALL files)
    for openboxrofi in /etc/openflexos/home/user/config/openbox/rofi/*; do
        ln -sf "$openboxrofi" "/etc/skel/.config/openbox/rofi/$(basename "$openboxrofi")"
    done

    # Oh My Posh
    for ohmyposh in /etc/openflexos/home/user/config/ohmyposh/*; do
        ln -sf "$ohmyposh" "/etc/skel/.config/ohmyposh/$(basename "$ohmyposh")"
    done

    # SXIV Key Handler
    for sxiv in /etc/openflexos/home/user/config/sxiv/exec/*; do
        ln -sf "$sxiv" "/etc/skel/.config/sxiv/exec/$(basename "$sxiv")"
    done

    # Web bookmarks
    for webbookmarks in /etc/openflexos/home/user/config/web_bookmarks/*; do
        ln -sf "$webbookmarks" "/etc/skel/.config/web_bookmarks/$(basename "$webbookmarks")"
    done

    # Dunst
    for dunst in /etc/openflexos/home/user/config/dunst/*; do
        ln -sf "$dunst" "/etc/skel/.config/dunst/$(basename "$dunst")"
    done

    # Alacritty
    for alacritty in /etc/openflexos/home/user/config/alacritty/*; do
        ln -sf "$alacritty" "/etc/skel/.config/alacritty/$(basename "$alacritty")"
    done

    # GTK 3
    for gtk3 in /etc/openflexos/home/user/config/gtk-3.0/*; do
        ln -sf "$gtk3" "/etc/skel/.config/gtk-3.0/$(basename "$gtk3")"
    done

    # GTK 4
    for gtk4 in /etc/openflexos/home/user/config/gtk-4.0/*; do
        ln -sf "$gtk4" "/etc/skel/.config/gtk-4.0/$(basename "$gtk4")"
    done

    # MyThemes
    for mythemes in /etc/openflexos/home/user/config/MyThemes/*; do
        ln -sf "$mythemes" "/etc/skel/.config/MyThemes/$(basename "$mythemes")"
    done

    # Picom
    for picom in /etc/openflexos/home/user/config/picom/*; do
        ln -sf "$picom" "/etc/skel/.config/picom/$(basename "$picom")"
    done

    # Qt5
    for qt5 in /etc/openflexos/home/user/config/qt5ct/*; do
        ln -sf "$qt5" "/etc/skel/.config/qt5ct/$(basename "$qt5")"
    done

    # Qt6
    for qt6 in /etc/openflexos/home/user/config/qt6ct/*; do
        ln -sf "$qt6" "/etc/skel/.config/qt6ct/$(basename "$qt6")"
    done

    # Dotfiles (ALL dot.* files)
    for userhomedots in /etc/openflexos/home/user/dot.*; do
        ln -sf "$userhomedots" "/etc/skel/.${userhomedots#*.}"
    done

    # Wallpapers
    for wallpapers in /etc/openflexos/home/user/config/wallpapers/wallpaper_cave_nature/*; do
        ln -sf "$wallpapers" "/etc/skel/.config/wallpapers/wallpaper_cave_nature/$(basename "$wallpapers")"
    done
fi

if [[ $wm_dir == "qtile" ]]; then

    # Qtile main config (ALL files)
    for qtileconfig in /etc/openflexos/home/user/config/qtile/*; do
        ln -sf "$qtileconfig" "/etc/skel/.config/qtile/$(basename "$qtileconfig")"
    done

    # Rofi
    for qtilerofi in /etc/openflexos/home/user/config/qtile/rofi/*; do
        ln -sf "$qtilerofi" "/etc/skel/.config/qtile/rofi/$(basename "$qtilerofi")"
    done

    # Scripts (exclude menu-only ones)
    for qtilescripts in /etc/openflexos/usr/local/bin/*; do
        case "$(basename "$qtilescripts")" in
            OpenFlexOS_Power.sh|OpenFlexOS_SSH.sh|OpenFlexOS_WebBookmarker.sh|OpenFlexOS_CleanUp.sh)
                continue
            ;;
        esac
        ln -sf "$qtilescripts" "/etc/skel/.config/qtile/scripts/$(basename "$qtilescripts")"
    done

    # Menu scripts
    for qtilescriptsmenu in OpenFlexOS_Power.sh OpenFlexOS_SSH.sh OpenFlexOS_WebBookmarker.sh OpenFlexOS_CleanUp.sh UpdateTheme; do
        clean_name="${qtilescriptsmenu#OpenFlexOS_}"
        clean_name="${clean_name%.sh}"
        ln -sf "/etc/openflexos/usr/local/bin/$qtilescriptsmenu" \
               "/etc/skel/.config/qtile/scripts/menu/$clean_name"
    done

    # Sounds
    for qtilesounds in /etc/openflexos/home/user/config/sounds/*; do
        ln -sf "$qtilesounds" "/etc/skel/.config/qtile/sounds/$(basename "$qtilesounds")"
    done

    # Shared configs
    for dir in ohmyposh sxiv/exec web_bookmarks dunst alacritty gtk-3.0 gtk-4.0 MyThemes picom qt5ct qt6ct; do
        for file in /etc/openflexos/home/user/config/$dir/*; do
            ln -sf "$file" "/etc/skel/.config/$dir/$(basename "$file")"
        done
    done

    for file in themes.json dmenu_theme.conf; do
    ln -sf "/etc/openflexos/home/user/config/$file" \
           "/etc/skel/.config/$file"
    done

    # Dotfiles
    for userhomedots in /etc/openflexos/home/user/dot.*; do
        ln -sf "$userhomedots" "/etc/skel/.${userhomedots#*.}"
    done

    # Wallpapers
    for wallpapers in /etc/openflexos/home/user/config/wallpapers/wallpaper_cave_nature/*; do
        ln -sf "$wallpapers" "/etc/skel/.config/wallpapers/wallpaper_cave_nature/$(basename "$wallpapers")"
    done
fi

echo ">> /etc/skel prepared with symlinks for $wm_dir"

# -------------------------
# Main loop
# -------------------------
while true; do
    # Get real users (UID >= 1000 and not nobody)
    all_users=($(awk -F: '($3 >= 1000) && ($1 != "nobody") { print $1 }' /etc/passwd))

    # Filter users missing this WM config
    missing_users=()
    for user in "${all_users[@]}"; do
        if [ ! -d "/home/$user/.config/$wm_dir" ]; then
            missing_users+=("$user")
        fi
    done

    clear
    echo "Select a user to set up $wm_dir from /etc/skel:"
    index=1
    for user in "${missing_users[@]}"; do
        echo "$index) $user"
        ((index++))
    done
    echo "$index) Create a new user"
    ((index++))
    echo "$index) Return to main menu"

    read -p "Choose an option: " choice

    if [[ "$choice" -ge 1 && "$choice" -le "${#missing_users[@]}" ]]; then
        selected_user="${missing_users[$((choice-1))]}"
        user_home="/home/$selected_user"

        echo ">> Copying from /etc/skel to $selected_user..."
        cp -a /etc/skel/. "$user_home/"
        chown -R "$selected_user:$selected_user" "$user_home"

    elif [[ "$choice" -eq $((${#missing_users[@]}+1)) ]]; then
        read -p "Enter new username: " newuser
        if id "$newuser" &>/dev/null; then
            echo "User '$newuser' already exists."
            sleep 2
            continue
        else
            useradd -m "$newuser"
            passwd "$newuser"
            read -p "Add '$newuser' to sudo group? (y/n): " yn
            [[ "$yn" =~ ^[Yy]$ ]] && usermod -aG wheel "$newuser"
            echo ">> New user '$newuser' created with configs from /etc/skel"
        fi

    elif [[ "$choice" -eq $((${#missing_users[@]}+2)) ]]; then
        echo "Returning to main menu..."
        sleep 1
        exit 0
    else
        echo "Invalid selection."
        sleep 2
    fi
done
