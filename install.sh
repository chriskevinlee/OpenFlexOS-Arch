#!/bin/bash
clear

# Ensure script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0"
    exit 1
fi
clear

# Confirm installation
while true; do
    read -p "Would you like to install OpenFlexOS? (y/n): " yn
    case "$yn" in
        [Yy]* ) break ;;
        [Nn]* ) echo "Exiting installer."; exit 0 ;;
        * ) echo "Invalid input. Please enter y or n." ;;
    esac
done

# Ask to update system
while true; do
    read -p "Would you like to run system updates? (y/n): " yn
    case "$yn" in
        [Yy]* )
            echo ">> Running system update..."
            pacman --noconfirm -Syu
            break
            ;;
        [Nn]* ) break ;;
        * ) echo "Invalid input. Please enter y or n." ;;
    esac
done
clear


# Menu options
options=("Qtile" "OpenBox" "Exit Installation Script" "Reboot" "Power Off")
PS3="Please choose an option (1-${#options[@]}): "
echo "Please Choose a Window Manager to install or a action to perform"

select choice in "${options[@]}"; do
    case "$choice" in
        "Qtile")
            echo ">> Setting up prerequisites ..."
            bash ./modules/prerequisites.sh
            clear

            echo ">> Installing Qtile..."
            bash ./modules/WindowManagers.sh -Q
            clear
            
            # echo ">> Copying Qtile configs to /etc/skel..."
            # bash ./modules/WM_to_etc.sh -Q
            # clear
            
            echo ">> Installing additional packages..."
            bash ./modules/Packages.sh
            clear
            
            echo ">> Applying miscellaneous configurations..."
            bash ./modules/Miscellaneous_Configs.sh
            clear

            echo ">> Copy Qtile configs to users or add a new user..."
            bash ./modules/Users.sh -Q
            clear
            ;;
        "OpenBox")
            echo ">> Setting up prerequisites ..."
            bash ./modules/prerequisites.sh
            clear

            echo ">> Installing OpenBox..."
            bash ./modules/WindowManagers.sh -O
            clear
            
            # echo ">> Copying OpenBox configs to /etc/skel..."
            # bash ./modules/WM_to_etc.sh -O
            #clear
            
            echo ">> Installing additional packages..."
            bash ./modules/Packages.sh
            clear
            
            echo ">> Applying miscellaneous configurations..."
            bash ./modules/Miscellaneous_Configs.sh
            clear

            echo ">> Copy OpenBox configs to users or add a new user..."
            bash ./modules/Users.sh -O
            clear
            ;;
        "Exit Installation Script")
            echo ">> Exiting installation script..."
            sleep 2
            exit 0
            ;;
        "Reboot")
            echo ">> Rebooting system..."
            reboot
            ;;
        "Power Off")
            echo ">> Powering off system..."
            poweroff
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
    REPLY=
    echo ""
    echo ">> Choose another option or exit:"
done