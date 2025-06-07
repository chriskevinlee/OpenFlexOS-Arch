#!/bin/bash

# Determine which WM was selected
while getopts "OQ" opt; do
  case "$opt" in
    O) WM="openbox" ;;
    Q) WM="qtile" ;;
    *) echo "Usage: $0 [-O | -Q]"; exit 1 ;;
  esac
done

if [[ -z "$WM" ]]; then
    echo "Error: No window manager specified. Use -O for OpenBox or -Q for Qtile."
    exit 1
fi

while true; do
    # Detect users missing $WM config
    missing_users=()
    while IFS=: read -r username _ _ _ _ home_dir _; do
        [[ "$home_dir" == /home/* && -d "$home_dir" ]] || continue
        [[ ! -d "$home_dir/.config/$WM" ]] && missing_users+=("$username")
    done < /etc/passwd

    echo
    echo "Select a user to copy missing files from /etc/skel:"
    for i in "${!missing_users[@]}"; do
        echo "$((i + 1)). ${missing_users[$i]}"
    done
    echo "$(( ${#missing_users[@]} + 1 )). Add a New User"

    read -p "Choose an option: " choice
    index=$((choice - 1))

    # Add new user option
    if [[ "$choice" -eq $(( ${#missing_users[@]} + 1 )) ]]; then
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

    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$index" -ge 0 ] && [ "$index" -lt "${#missing_users[@]}" ]; then
        user="${missing_users[$index]}"
        home_dir=$(getent passwd "$user" | cut -d: -f6)
        echo "Copying $WM config to $user..."

        mkdir -p "$home_dir/.config"
        cp -r "/etc/skel/.config/$WM" "$home_dir/.config/"
        chown -R "$user:$user" "$home_dir/.config/$WM"

        echo "Done."
    else
        echo "Invalid selection."
    fi

    # Refresh list — stop loop if no more missing users
    remaining=()
    while IFS=: read -r username _ _ _ _ home_dir _; do
        [[ "$home_dir" == /home/* && -d "$home_dir" ]] || continue
        [[ ! -d "$home_dir/.config/$WM" ]] && remaining+=("$username")
    done < /etc/passwd

    if [[ "${#remaining[@]}" -eq 0 ]]; then
        echo "All users have '$WM' configs."
        echo
        echo "Select a user to copy missing files from /etc/skel:"
        echo "1. Add a New User"
        read -p "Choose an option: " final_choice
        if [[ "$final_choice" == "1" ]]; then
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
        fi
        break
    fi
done
