#!/bin/bash
clear

# Detect which WM config is present in /etc/skel
if [ -d /etc/skel/.config/qtile ]; then
    wm_dir=".config/qtile"
elif [ -d /etc/skel/.config/openbox ]; then
    wm_dir=".config/openbox"
else
    echo "Error: No supported window manager config found in /etc/skel."
    sleep 2
    exit 1
fi

# Get all real users (UID >= 1000 and not nobody)
all_users=($(awk -F: '($3 >= 1000) && ($1 != "nobody") { print $1 }' /etc/passwd))

# Find users missing the WM config
missing_users=()
for user in "${all_users[@]}"; do
    if [ ! -e "/home/$user/$wm_dir" ]; then
        missing_users+=("$user")
    fi
done

# Display options
echo "Select a user to copy missing files from /etc/skel:"
index=1
for user in "${missing_users[@]}"; do
    echo "$index) $user"
    ((index++))
done
echo "$index) Add a New User"

read -p "Choose an option: " choice

if [[ "$choice" -ge 1 && "$choice" -le "${#missing_users[@]}" ]]; then
    selected_user="${missing_users[$((choice-1))]}"
    echo ">> Copying $wm_dir config to $selected_user..."
    cp -rn /etc/skel/. /home/"$selected_user"/
    chown -R "$selected_user":"$selected_user" /home/"$selected_user"/
    echo ">> Done. Returning to main menu..."
    sleep 2
elif [[ "$choice" -eq "$index" ]]; then
    read -p "Enter new username: " newuser
    if id "$newuser" &>/dev/null; then
        echo "User '$newuser' already exists."
    else
        useradd -m -k /etc/skel "$newuser"
        passwd "$newuser"
        read -p "Add '$newuser' to sudo group? (y/n): " yn
        [[ "$yn" =~ ^[Yy]$ ]] && usermod -aG wheel "$newuser"
        echo "User '$newuser' created successfully."
    fi
    echo ">> Returning to main menu..."
    sleep 2
else
    echo "Invalid selection."
    sleep 2
fi
