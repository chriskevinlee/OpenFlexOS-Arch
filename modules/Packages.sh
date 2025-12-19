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
EOF
}


PKG=qtile-extras
BUILD_USER=_aurbuilder
BUILD_HOME=/tmp/${BUILD_USER}-home
BUILD_DIR=/tmp/${PKG}-build


echo "[+] Installing base tools..."
pacman -Sy --noconfirm --needed git base-devel

# Create temporary build user
if ! id "$BUILD_USER" &>/dev/null; then
    echo "[+] Creating temporary build user ($BUILD_USER)"
    useradd -r -m -d "$BUILD_HOME" -s /bin/bash "$BUILD_USER"
fi

# Give that user password-less pacman rights just for building
# (makepkg uses sudo pacman -S to pull missing deps)
echo "[+] Temporarily allowing $BUILD_USER to run pacman without password..."
echo "$BUILD_USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/$BUILD_USER
chmod 440 /etc/sudoers.d/$BUILD_USER

# Prepare build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
chown -R "$BUILD_USER":"$BUILD_USER" "$BUILD_DIR" "$BUILD_HOME"

echo "[+] Cloning AUR repo..."
sudo -u "$BUILD_USER" bash -c "
    cd '$BUILD_DIR'
    git clone https://aur.archlinux.org/${PKG}.git . >/dev/null 2>&1 || true
    git pull --ff-only || true
"

echo "[+] Building package..."
sudo -u "$BUILD_USER" bash -c "
    cd '$BUILD_DIR'
    export HOME='$BUILD_HOME'
    makepkg -s --noconfirm --skippgpcheck
"

# Find the built package
PKGFILE=$(find "$BUILD_DIR" -maxdepth 1 -type f -name "${PKG}-*.pkg.tar.*" | sort -V | tail -n1)
if [[ -z "$PKGFILE" ]]; then
    echo "[-] Build failed: no package produced."
    rm -f /etc/sudoers.d/$BUILD_USER
    userdel -r "$BUILD_USER" 2>/dev/null || true
    exit 1
fi

echo "[+] Installing ${PKGFILE}..."
pacman -U --noconfirm "$PKGFILE"

echo "[+] Cleaning up temporary files and user..."
rm -rf "$BUILD_DIR" "$BUILD_HOME"
rm -f /etc/sudoers.d/$BUILD_USER
userdel -r "$BUILD_USER" 2>/dev/null || true

echo "[✓] qtile-extras installed successfully."

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

### install ohmyposh
sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin

git clone https://github.com/L4ki/Viola-Plasma-Themes /tmp/Viola-Plasma-Themes
cp -r "/tmp/Viola-Plasma-Themes/Viola GTK Themes/Viola-Dark-GTK" /usr/share/themes
