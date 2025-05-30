#!/bin/bash

# Enable dotglob to include hidden files (dotfiles)
shopt -s dotglob

# Get all files and directories in /etc/skel
skel_items=()
for item in /etc/skel/*; do
    [ -e "$item" ] && skel_items+=("$(basename "$item")")
done

# Array to hold users missing at least one file from /etc/skel
valid_users=()
while IFS=: read -r username _ _ _ _ home_dir _; do
    case "$home_dir" in
        /home/*)
            if [ -d "$home_dir" ]; then
                missing=0
                for skel_item in "${skel_items[@]}"; do
                    if [ ! -e "$home_dir/$skel_item" ]; then
                        missing=1
                        break
                    fi
                done

                [ "$missing" -eq 1 ] && valid_users+=("$username")
            fi
            ;;
    esac
done < /etc/passwd

# Display menu
echo "Select a user to copy missing files from /etc/skel:"
for i in "${!valid_users[@]}"; do
    echo "$((i + 1)). ${valid_users[$i]}"
done
echo "$(( ${#valid_users[@]} + 1 )). Add a New User"

# Get selection
read -p "Choose an option: " choice
index=$((choice - 1))

# Add new user
if [[ "$choice" -eq $(( ${#valid_users[@]} + 1 )) ]]; then
    read -p "Enter new username: " newuser

    if id "$newuser" &>/dev/null; then
        echo "User '$newuser' already exists."
        exit 1
    fi

    # Create user with home and skel files
    useradd -m -k /etc/skel "$newuser"
    if [ $? -ne 0 ]; then
        echo "Failed to create user."
        exit 1
    fi

    # Set password
    echo "Set a password for $newuser:"
    passwd "$newuser"

    # Ask if user should be sudoer
    read -p "Should '$newuser' be added to the sudo group? (y/n): " sudo_choice
    if [[ "$sudo_choice" =~ ^[Yy]$ ]]; then
        usermod -aG wheel "$newuser"
        echo "'$newuser' added to the sudo group."
    else
        echo "'$newuser' was not added to the sudo group."
    fi

    echo "User '$newuser' created successfully."
    exit 0
fi

# Handle selection from list
if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$index" -ge 0 ] && [ "$index" -lt "${#valid_users[@]}" ]; then
    selected_user="${valid_users[$index]}"
    home_dir=$(getent passwd "$selected_user" | cut -d: -f6)

    echo "Copying missing files to $selected_user..."

    for skel_item in "${skel_items[@]}"; do
        src="/etc/skel/$skel_item"
        dest="$home_dir/$skel_item"
        if [ ! -e "$dest" ]; then
            cp -r "$src" "$dest"
            chown -R "$selected_user:$selected_user" "$dest"
            echo "Copied: $skel_item"
        fi
    done

    echo "Done."
else
    echo "Invalid selection."
    exit 1
fi