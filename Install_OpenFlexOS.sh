#!/bin/bash
 
# Check to make sure script has root/sudo permissions
    if [ "$(id -u)" -ne 0 ]; then
        echo "Please run this script with sudo:"
        echo "sudo $0"
        exit 1
    fi

# Clear's output, Welcomes and ask the user if like to install OpenFlexOS
    clear
    echo "Welcome to OpenFlexOS Installation script"
    read -p "Would you like to start installing OpenFlexOS? (y/n) " yn

# Displays a invalid input message to the user if y or n is not selected
    while [[ ! $yn =~ ^(y|n)$ ]]; do
        clear
        echo "Invalid Input. You Entered $yn"
        read -p "Would you like to start installing OpenFlexOS? (y/n) " yn
    done

# Function: List of packages to be install
    install_packages () {
        pacman --noconfirm --needed -S sddm # Display Manager(login manager)
        pacman --noconfirm --needed -S mpv # For login,logout,lock,reboot and shutdown sounds
        pacman --noconfirm --needed -S xscreensaver # Screensaver
        pacman --noconfirm --needed -S feh # To set wallpapers
        pacman --noconfirm --needed -S rofi # For Application and power Laucher
        pacman --noconfirm --needed -S dmenu # For Application and power Laucher
        pacman --noconfirm --needed -S arandr # To set Screen Resolution
        pacman --noconfirm --needed -S ttf-nerd-fonts-symbols # For icons
        pacman --noconfirm --needed -S xdg-user-dirs # Create user directories upon user creation
        pacman --noconfirm --needed -S alacritty # Terminal Appliction
        pacman --noconfirm --needed -S lsd # coloured ls output
        pacman --noconfirm --needed -S bat # replacement for cat with coloured output
        pacman --noconfirm --needed -S pavucontrol-qt # Audio Control GUI
        pacman --noconfirm --needed -S pipewire-pulse # Audio Control
        pacman --noconfirm --needed -S git # to download git packages
        pacman --noconfirm --needed -S qt5-graphicaleffects qt5-quickcontrols2 qt5-svg # for sddm theme
        pacman --noconfirm --needed -S zsh # zsh Shell
        pacman --noconfirm --needed -S zsh-history-substring-search # for zsh shell allows to search throught typed commands
        pacman --noconfirm --needed -S zsh-syntax-highlighting # for the zsh shell will show vaild commands in green and invaild commands in red
        pacman --noconfirm --needed -S zsh-autosuggestions # for the zsh shell wil show suggested typed commands
        pacman --noconfirm --needed -S wget # To Download zsh-sudo plugin for zsh
        pacman --noconfirm --needed -S firefox # Default Web Browser
        pacman --noconfirm --needed -S flameshot # For screenshots
        pacman --noconfirm --needed -S htop # Terminal System Monitor
        pacman --noconfirm --needed -S caja # A file Manager
        pacman --noconfirm --needed -S xarchiver # Archiver to work with file manager pcmanfm
        pacman --noconfirm --needed -S p7zip
        pacman --noconfirm --needed -S unzip # Add zip support to xarchiver
        pacman --noconfirm --needed -S polkit-gnome # Polkit authentication
        pacman --noconfirm --needed -S sxiv # To Apply Wallpapers with a script
        pacman --noconfirm --needed -S qt5ct # GUI apply theme for qt5
        pacman --noconfirm --needed -S qt6ct # GUI apply theme for qt6
        pacman --noconfirm --needed -S kvantum-qt5 # GUI apply theme for qt
        pacman --noconfirm --needed -S lxappearance-gtk3 # GUI apply theme for GTK
        pacman --noconfirm --needed -S materia-gtk-theme # A GTK theme
        pacman --noconfirm --needed -S dunst # Notification System
        pacman --noconfirm --needed -S picom # Compositor for effect
        pacman --noconfirm --needed -S wmctrl # To change sxiv window title, used in OpenFlexOS_WallpaperChanger.sh
        pacman --noconfirm --needed -S xf86-input-libinput xbindkeys sxhkd playerctl
        pacman --noconfirm --needed -S galculator
        pacman --noconfirm --needed -S zenity
        pacman --noconfirm --needed -S python-psutil
        pacman --noconfirm --needed -S pacman-contrib
        pacman --noconfirm --needed -S pkgfile

        pacman --noconfirm --needed -S gcc
        pacman --noconfirm --needed -S pkg-config
        pacman --noconfirm --needed -S python
        pacman --noconfirm --needed -S meson
        pacman --noconfirm --needed -S ninja
        pacman --noconfirm --needed -S xcb-util
        pacman --noconfirm --needed -S libx11
        pacman --noconfirm --needed -S pixman
        pacman --noconfirm --needed -S libdbus
        pacman --noconfirm --needed -S libconfig
        pacman --noconfirm --needed -S libepoxy
        pacman --noconfirm --needed -S libev
        pacman --noconfirm --needed -S uthash

        cd /tmp
        git clone https://github.com/FT-Labs/picom.git
        cd picom
        meson setup --buildtype=release build
        ninja -C build
        ninja -C build install

        echo "Installing python3-pip..."
        pacman --noconfirm --needed -S python3 xdotool
        
        echo "Cloning nerd-dictation..."
        git clone https://github.com/ideasman42/nerd-dictation.git /opt/nerd-dictation
        cd /opt/nerd-dictation
        
        echo "Creating and activating virtual environment..."
        python3 -m venv vosk-venv
        source vosk-venv/bin/activate
        
        echo "Downloading Vosk model..."
        wget -q --show-progress https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip
        
        echo "Extracting Vosk model..."
        unzip -q vosk-model-small-en-us-0.15.zip
        mv vosk-model-small-en-us-0.15 model
        
        echo "Installing Vosk inside virtual environment..."
        pip install vosk

    }

# Function: Get zsh path, checks to see if any users already exists if not it ask the user to create a user and allows user to copy config files to already existing users and added users
    users_function() {

    get_zsh_path() {
        if [[ -x /bin/zsh ]]; then
            echo "/bin/zsh"
        elif [[ -x /usr/bin/zsh ]]; then
            echo "/usr/bin/zsh"
        else
            echo "zsh not found" >&2
            exit 1
        fi
    }

    zsh_path=$(get_zsh_path)

   while true; do  # Start a loop to repeat the process
    clear
    # Get the list of users again (including any newly added users)
    users=($(grep "/home/" /etc/passwd | awk -F : '{print $1}'))

    # This code will run if there ARE users on the system with Home Directories
    if [[ ${#users[@]} -ge 0 ]]; then
        # Declare an empty array to store users without the file
        missing_users=()

        # Loop through users and check for the existence of the file
        for user in "${users[@]}"; do
            user_home=$(eval echo "~$user")  # Get the home directory for each user
            if [[ ! -d "$user_home/.config/$lower_main" ]]; then
                missing_users+=("$user")  # Add user to the list of missing users
            fi
        done

        # Display the users who are missing the file
        echo "These users do not have $main configuration directory and files:"
        for ((i = 0; i < ${#missing_users[@]}; i++)); do
            echo "$(($i + 1)). ${missing_users[i]}"
        done

        echo "0. Add a new user"  # Option to add a new user
        echo "q. Quit To Main Menu"  # Option to quit the loop

        # Ask for user input to copy the file
        echo "Please enter the number(s) of the user(s) you want to copy the file to (comma-separated, e.g., 1,2,3), 0 to add a new user, or 'q' to quit:"
        read -r user_input

        # Handle quit option
        if [[ $user_input == "q" ]]; then
            echo "Exiting..."
            break
        fi

        # Convert input into an array
        selected_users=($(echo "$user_input" | tr ',' ' '))

        # Handle the case for creating a new user
        if [[ " ${selected_users[@]} " =~ " 0 " ]]; then
            read -p "Please Enter a username: " username
            while [[ -z $username ]]; do
                echo "Invalid Input"
                read -p "Please Enter a username: " username
            done

            sudo useradd -m $username
            sudo passwd $username

            read -p "Would you like to make $username a sudo user? y/n " yn
            while [[ -z $yn ]] || [[ ! $yn =~ [yn] ]]; do
                echo "Invalid Input"
                read -p "Would you like to make $username a sudo user? y/n " yn
            done
            if [[ $yn = y ]]; then
                sudo usermod -aG wheel $username
            fi

            # Add new user to the missing_users array for copying files
            missing_users+=("$username")
        fi

        # Copy the file to selected users' home directories
        for idx in "${selected_users[@]}"; do
            # Skip option "0" as it has already been handled
            if [[ $idx == 0 ]]; then
                continue
            fi

            user_to_copy=${missing_users[$((idx - 1))]}  # Adjust for 0-based index
            user_home=$(eval echo "~$user_to_copy")
            echo "Copying files to $user_home"

            mkdir -p $user_home/.config
            cp -r OpenFlexOS-Configs/config/$lower_main $user_home/.config/$lower_main
            cp -r OpenFlexOS-Configs/config/gtk-3.0 $user_home/.config/gtk-3.0
            cp -r OpenFlexOS-Configs/config/Kvantum/ $user_home/.config/Kvantum
            cp -r OpenFlexOS-Configs/config/qt5ct/ $user_home/.config/qt5ct
            cp -r OpenFlexOS-Configs/config/qt6ct/ $user_home/.config/qt6ct
            cp -r OpenFlexOS-Configs/config/picom $user_home/.config/picom
            cp -r OpenFlexOS-Configs/config/sxiv $user_home/.config/sxiv
            cp -r OpenFlexOS-Configs/config/wallpapers/ $user_home/.config/wallpapers/
            cp OpenFlexOS-Configs/dot.gtkrc-2.0 $user_home/.gtkrc-2.0
            cp OpenFlexOS-Configs/dot.xscreensaver $user_home/.xscreensaver
            cp OpenFlexOS-Configs/dot.zshrc $user_home/.zshrc
            cp OpenFlexOS-Configs/dot.bashrc $user_home/.bashrc
            cp -r OpenFlexOS-Configs/config/ohmyposh/ $user_home/.config/
            sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin
            chsh -s "$zsh_path" $user_to_copyf
            chown -R $user_to_copy:$user_to_copy $user_home
            chmod -R +x $user_home/.config/$lower_main/scripts/
        done

        # Refresh the missing_users array after copying files
        missing_users=()
    else
        echo "No users with home directories found."
        break  # Exit the loop if no users are found
    fi
    done  # End of loop
    }

# Function: Set environment variables for qt and gtk theme
    set_env_variables() {
        echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
        echo "QT_AUTO_SCREEN_SCALE_FACTOR=0" >> /etc/environment
        echo "QT_SCALE_FACTOR=1" >> /etc/environment
        echo "QT_FONT_DPI=96" >> /etc/environment
    }

# Function: clone configs
    clone_configs () {
        git clone https://github.com/chriskevinlee/OpenFlexOS-Configs.git
    }


# Function: Enables sddm and copy config files
    enable_copytheme_ssdm () {
        systemctl enable sddm
        cp -r OpenFlexOS-Configs/corners /usr/share/sddm/themes/
        cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf
        sed -i s/Current=/Current=corners/ /etc/sddm.conf
    }

# Function: Copy config files to /etc/skel for newly created users
    copy_config_skel () {
        if [[ ! -d /etc/skel/.config ]]; then
            mkdir /etc/skel/.config
            if [[ ! -d /etc/skel/.config/wallpapers ]]; then
                cp -r OpenFlexOS-Configs/config/wallpapers/ /etc/skel/.config/wallpapers/
            else
                echo "Wallpapers directory already exists. Skipping copy."
            fi
            cp -r OpenFlexOS-Configs/config/$lower_main /etc/skel/.config/$lower_main
            cp -r OpenFlexOS-Configs/config/gtk-3.0 /etc/skel/.config/gtk-3.0
            cp -r OpenFlexOS-Configs/config/Kvantum/ /etc/skel/.config/Kvantum
            cp -r OpenFlexOS-Configs/config/qt5ct/ /etc/skel/.config/qt5ct
            cp -r OpenFlexOS-Configs/config/qt6ct/ /etc/skel/.config/qt6ct
            cp -r OpenFlexOS-Configs/config/picom /etc/skel/.config/picom
            cp -r OpenFlexOS-Configs/config/sxiv /etc/skel/.config/sxiv
            cp OpenFlexOS-Configs/dot.gtkrc-2.0 /etc/skel/.gtkrc-2.0
            cp OpenFlexOS-Configs/dot.xscreensaver /etc/skel/.xscreensaver
            cp OpenFlexOS-Configs/dot.zshrc /etc/skel/.zshrc
            cp OpenFlexOS-Configs/dot.bashrc /etc/skel/.bashrc
            cp -r OpenFlexOS-Configs/config/ohmyposh/ /etc/skel/.config/
            chmod -R +x /etc/skel/.config/$lower_main/scripts/
            sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin
        elif [[  -d /etc/skel/.config ]]; then
            if [[ ! -d /etc/skel/.config/wallpapers ]]; then
                cp -r OpenFlexOS-Configs/config/wallpapers/ /etc/skel/.config/wallpapers/
            else
                echo "Wallpapers directory already exists. Skipping copy."
            fi
            cp -r OpenFlexOS-Configs/config/$lower_main /etc/skel/.config/$lower_main
            cp -r OpenFlexOS-Configs/config/gtk-3.0 /etc/skel/.config/gtk-3.0
            cp -r OpenFlexOS-Configs/config/Kvantum/ /etc/skel/.config/Kvantum
            cp -r OpenFlexOS-Configs/config/qt5ct/ /etc/skel/.config/qt5ct
            cp -r OpenFlexOS-Configs/config/qt6ct/ /etc/skel/.config/qt6ct
            cp -r OpenFlexOS-Configs/config/picom /etc/skel/.config/picom
            cp -r OpenFlexOS-Configs/config/sxiv /etc/skel/.config/sxiv
            cp OpenFlexOS-Configs/dot.gtkrc-2.0 /etc/skel/.gtkrc-2.0
            cp OpenFlexOS-Configs/dot.xscreensaver /etc/skel/.xscreensaver
            cp OpenFlexOS-Configs/dot.zshrc /etc/skel/.zshrc
            cp OpenFlexOS-Configs/dot.bashrc /etc/skel/.bashrc
            cp -r OpenFlexOS-Configs/config/ohmyposh/ /etc/skel/.config/
            chmod -R +x /etc/skel/.config/$lower_main/scripts/
            sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin    
        fi
    }

# Function: Miscellaneous configurations 
    miscellaneous_configs () {
        cp OpenFlexOS-Configs/nd /usr/local/bin/nd
        chmod +x /usr/local/bin/nd
        cp OpenFlexOS-Configs/OpenFlexOS_WallpaperChanger.sh /usr/local/bin/OpenFlexOS_WallpaperChanger.sh
        chmod +x /usr/local/bin/OpenFlexOS_WallpaperChanger.sh
        cp OpenFlexOS-Configs/wallpaper.desktop /usr/share/applications/wallpaper.desktop

        cp -r OpenFlexOS-Configs/Midnight-Red /usr/share/themes/Midnight-Red
        cp -r OpenFlexOS-Configs/Midnight-Green /usr/share/themes/Midnight-Green
        cp -r OpenFlexOS-Configs/Arc-Darkest /usr/share/themes/Arc-Darkest
        cp -r OpenFlexOS-Configs/Vivid-Dark-Icons /usr/share/icons/Vivid-Dark-Icons
                            
        mkdir /usr/share/zsh/plugins/zsh-sudo
        wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh -P /usr/share/zsh/plugins/zsh-sudo
        pkgfile -u
                            
        clear
        sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        sed -i  's|SHELL=/usr/bin/bash|SHELL=/usr/bin/zsh|' /etc/default/useradd
        sed -i 's/#Color/Color/' /etc/pacman.conf
        sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
        sed -i '/^#ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf
        
        # Setup hibination
        SWAP_INFO=$(swapon --show --noheadings)
        SWAP_DEVICE=$(echo "$SWAP_INFO" | awk '{print $1}')
        sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block filesystems keyboard resume fsck)/' /etc/mkinitcpio.conf
        mkinitcpio -P
        sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"resume=$SWAP_DEVICE\"|" /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
        clear
    }

# If the User selects y the installation will start
    if [[ $yn = y ]]; then
    read -p "Would you like to update? (y/n) " yn

    # Gives a invaild input message if y or n is not entered
    while [[ ! $yn = y ]] && [[ ! $yn = n ]]; do
        clear
        echo "Invaild Input! You Entered $yn"
        read -p "Would you like to update? (y/n) " yn
    done

    # Runs system updates if y is selected
    if [[ $yn = y ]]; then
        echo "Updating..."
        sleep 5
        pacman --noconfirm -Syu
    fi
    clear

    # Set's a array, asks the user which window manager to install and sets a promt to tell the user to use a number
    options=("Qtile" "Openbox" "User Configuration" "Exit Installation Script" "Reboot" "PowerOff")
    echo "Please Choose a Window Manager to install"
    PS3="Please Choose a Number: "

    select main in "${options[@]}"
        do
        case $main in
            # Installs everything needed to run Qtile
                "Qtile" )
                    lower_main=$(echo "$main" | tr '[:upper:]' '[:lower:]')

                    clear
                    echo "Installing required packages for Qtile-OpenFlexOS..."
                    sleep 5
                    pacman --noconfirm --needed -S qtile
                    install_packages

                    clone_configs
                    
                    enable_copytheme_ssdm

                    copy_config_skel

                    set_env_variables

                    miscellaneous_configs

                    mv /usr/share/wayland-sessions/qtile-wayland.desktop /usr/share/wayland-sessions/qtile-wayland.desktop.bak

                    users_function
                ;;
                "Openbox" )
                    lower_main=$(echo "$main" | tr '[:upper:]' '[:lower:]')

                    echo "Installing required packages for Openbox-OpenFlexOS..."
                    sleep 5
                    pacman --noconfirm --needed -S openbox # Window Manager
                    pacman --noconfirm --needed -S tint2 # status bar Window Manager
                    pacman --noconfirm --needed -S obconf # Set Openbox Theme
                    install_packages

                    clone_configs
                    
                    enable_copytheme_ssdm

                    copy_config_skel

                    set_env_variables

                    miscellaneous_configs

                    cp -r OpenFlexOS-Configs/Vedanta-dark-openbox /usr/share/themes/Vedanta-dark-openbox

                    users_function
                ;;
                "User Configuration" )
                    clear
                    while true; do
                        read -p "To copy configuration files, Please Choose a Window Manager (openbox, qtile) or leave blank to add a user: " wm
                        if [[ $wm = openbox ]]; then
                            lower_main=openbox
                            users_function
                            break
                        elif [[ $wm = qtile ]]; then
                            lower_main=qtile
                            users_function
                            break
                        elif [[ -z $wm ]]; then
                            users_function
                            break
                        else
                            clear
                            echo "Invalid Input..."
                        fi
                    done
                ;;
                "Exit Installation Script" )
                    echo "Exiting Installation Script..."
                    sleep 3
                    exit 0
                ;;
                "Reboot" )
                    reboot
                ;;
                "PowerOff" )
                    poweroff
                ;;
        esac
    clear
    echo "Please Choose a Window Manager to install"
    REPLY=
    done
    fi

# If the user enters n then the install it exit
    if [[ $yn = n ]]; then
        echo "Exiting OpenFlexOS Installation..."
        sleep 5
        exit 0
    fi
