Package_List() {
    echo sddm
    echo mpv
    echo xscreensaver
    echo feh
    echo rofi
    echo arandr
    echo ttf-nerd-fonts-symbols
    echo xdg-user-dirs
    echo alacritty
    echo lsd
    echo bat
    echo pavucontrol-qt
    echo pipewire-pulse
    echo git
    echo qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    echo zsh
    echo zsh-history-substring-search
    echo zsh-syntax-highlighting
    echo zsh-autosuggestions
    echo wget
    echo jq
    echo firefox
    echo flameshot
    echo htop
    echo caja
    echo xarchiver
    echo p7zip
    echo unzip
    echo polkit-gnome
    echo sxiv
    echo qt5ct
    echo qt6ct
    echo kvantum-qt5
    echo lxappearance-gtk3
    echo materia-gtk-theme
    echo dunst
    echo picom
    echo wmctrl
    echo xf86-input-libinput xbindkeys sxhkd playerctl
    echo deepin-calculator
    echo zenity
    echo python-psutil
    echo pacman-contrib
    echo pkgfile
    echo gcc
    echo pkg-config
    echo python
    echo meson
    echo ninja
    echo xcb-util
    echo libx11
    echo pixman
    echo libdbus
    echo libconfig
    echo libepoxy
    echo libev
    echo uthash
    echo base-devel
    echo git
    echo gvim
}

for package in $(Package_List); do
    pacman -S --noconfirm --needed "$package"
done


### Installing Picom
cd /tmp
git clone https://github.com/FT-Labs/picom.git
cd picom
meson setup --buildtype=release build
ninja -C build
ninja -C build install


### Installing nerd-dictation
#echo "Installing python3-pip..."
pacman --noconfirm --needed -S python3 xdotool    
#echo "Cloning nerd-dictation..."
git clone https://github.com/ideasman42/nerd-dictation.git /opt/nerd-dictation
cd /opt/nerd-dictation      
#echo "Creating and activating virtual environment..."
python3 -m venv vosk-venv
source vosk-venv/bin/activate
#echo "Downloading Vosk model..."
wget -q --show-progress https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip
#echo "Extracting Vosk model..."
unzip -q vosk-model-small-en-us-0.15.zip
mv vosk-model-small-en-us-0.15 model      
#echo "Installing Vosk inside virtual environment..."
pip install vosk



### Installing chriskevinlee's dmenu
git clone https://github.com/chriskevinlee/dmenu.git
cd dmenu
sudo make clean install
sudo make install
cd


### install ohmyposh
sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin



