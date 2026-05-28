#!/bin/bash

Package_List() {
  cat <<EOF
openflexos-configs
dmenu
mousepad
sddm
mpv
xclip
xscreensaver
feh
rofi
arandr
ttf-nerd-fonts-symbols
xdg-user-dirs
alacritty
lsd
bat
pavucontrol-qt
pipewire-pulse
git
qt5-graphicaleffects
qt5-quickcontrols2
qt5-svg
qt6-multimedia
qt6-5compat
zsh
zsh-history-substring-search
zsh-syntax-highlighting
zsh-autosuggestions
wget
jq
firefox
flameshot
htop
caja
xarchiver
p7zip
unzip
polkit-gnome
sxiv
qt5ct
qt6ct
kvantum-qt5
lxappearance-gtk3
materia-gtk-theme
dunst
picom
wmctrl
xf86-input-libinput
xbindkeys
sxhkd
playerctl
deepin-calculator
zenity
python-psutil
pacman-contrib
pkgfile
gcc
pkg-config
python
meson
ninja
xcb-util
libx11
pixman
libdbus
libconfig
libepoxy
libev
uthash
base-devel
vim
vim-nerdtree
powerline-fonts 
awesome-terminal-fonts 
nerd-fonts
lxappearance
conky
EOF
}

echo "[+] Installing base tools..."
pacman -Sy --noconfirm --needed git base-devel

# Install all
while read -r package; do
  sudo pacman -S --noconfirm --needed "$package"
done < <(Package_List)

yes | sudo pacman -S gvim

### Installing Picom
cd /tmp
git clone https://github.com/FT-Labs/picom.git
cd picom
meson setup --buildtype=release build
ninja -C build
ninja -C build install



### install ohmyposh
sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin

git clone https://github.com/L4ki/Viola-Plasma-Themes /tmp/Viola-Plasma-Themes
cp -r "/tmp/Viola-Plasma-Themes/Viola GTK Themes/Viola-Dark-GTK" /usr/share/themes
