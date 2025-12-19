# systemctl enable sddm
cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf
sed -i s/Current=/Current=openflexos-sddm-theme/ /etc/sddm.conf
systemctl enable sddm
ln -s /etc/openflexos/usr/share/sddm/themes/openflexos-sddm-theme /usr/share/sddm/themes/openflexos-sddm-theme
# make a directory for sddm avitars
mkdir -p /var/lib/AccountsService/icons/

chmod +x /etc/openflexos/usr/local/bin/*

ln -s /etc/openflexos/usr/share/applications/OpenFlexOS_Wallpaper.desktop /usr/share/applications/OpenFlexOS_Wallpaper.desktop
echo "export PATH='/etc/openflexos/usr/local/bin:$PATH'" > /etc/profile.d/custom_paths.sh

SWAP_INFO=$(swapon --show --noheadings)
SWAP_DEVICE=$(echo "$SWAP_INFO" | awk '{print $1}')
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block filesystems keyboard resume fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"resume=$SWAP_DEVICE\"|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

sed -i '$a # Preserve HOME when running vim via sudo\nDefaults!/usr/bin/vim env_keep += "HOME"' /etc/sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i  's|SHELL=/usr/bin/bash|SHELL=/usr/bin/zsh|' /etc/default/useradd
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i '/^#ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf

mkdir /usr/share/zsh/plugins/zsh-sudo
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh -P /usr/share/zsh/plugins/zsh-sudo
pkgfile -u

echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
echo "QT_AUTO_SCREEN_SCALE_FACTOR=0" >> /etc/environment
echo "QT_SCALE_FACTOR=1" >> /etc/environment
echo "QT_FONT_DPI=96" >> /etc/environment
