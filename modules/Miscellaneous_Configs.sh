# systemctl enable sddm
cp -r ./OpenFlexOS-Configs/corners /usr/share/sddm/themes/
cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf
sed -i s/Current=/Current=corners/ /etc/sddm.conf
systemctl enable sddm


cp ./OpenFlexOS-Configs/OpenFlexOS_WallpaperChanger.sh /usr/local/bin/OpenFlexOS_WallpaperChanger.sh
cp ./OpenFlexOS-Configs/OpenFlexOS_Wallpaper.desktop /usr/share/applications/OpenFlexOS_Wallpaper.desktop
chmod +x /usr/local/bin/OpenFlexOS_WallpaperChanger.sh



cp ./OpenFlexOS-Configs/nd /usr/local/bin/nd
chmod +x /usr/local/bin/nd


cp -r ./OpenFlexOS-Configs/config/dunst/ /etc/skel/.config/dunst/
cp -r ./OpenFlexOS-Configs/config/alacritty/ /etc/skel/.config/alacritty/
cp -r ./OpenFlexOS-Configs/config/MyThemes/ /etc/skel/.config/MyThemes/
cp -r ./OpenFlexOS-Configs/Midnight-Red /usr/share/themes/Midnight-Red
cp -r ./OpenFlexOS-Configs/Midnight-Green /usr/share/themes/Midnight-Green
cp -r ./OpenFlexOS-Configs/Arc-Darkest /usr/share/themes/Arc-Darkest
cp -r ./OpenFlexOS-Configs/Vivid-Dark-Icons /usr/share/icons/Vivid-Dark-Icons
cp -r ./OpenFlexOS-Configs/config/gtk-3.0 /etc/skel/.config/gtk-3.0
cp -r ./OpenFlexOS-Configs/config/gtk-4.0 /etc/skel/.config/gtk-4.0
cp -r ./OpenFlexOS-Configs/config/Kvantum/ /etc/skel/.config/Kvantum
cp -r ./OpenFlexOS-Configs/config/qt5ct/ /etc/skel/.config/qt5ct
cp -r ./OpenFlexOS-Configs/config/qt6ct/ /etc/skel/.config/qt6ct
cp -r ./OpenFlexOS-Configs/config/picom /etc/skel/.config/picom
cp ./OpenFlexOS-Configs/dot.gtkrc-2.0 /etc/skel/.gtkrc-2.0
cp ./OpenFlexOS-Configs/Generate_gtk_theme.sh /etc/skel/Generate_gtk_theme.sh
cp ./OpenFlexOS-Configs/Apply_theme.sh /etc/skel/Apply_theme.sh
cp -r ./OpenFlexOS-Configs/config/ohmyposh/ /etc/skel/.config/

cp -r ./OpenFlexOS-Configs/config/obmenu-generator /etc/skel/.config/





SWAP_INFO=$(swapon --show --noheadings)
SWAP_DEVICE=$(echo "$SWAP_INFO" | awk '{print $1}')
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block filesystems keyboard resume fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"resume=$SWAP_DEVICE\"|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg





sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i  's|SHELL=/usr/bin/bash|SHELL=/usr/bin/zsh|' /etc/default/useradd
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i '/^#ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf
        


mkdir /usr/share/zsh/plugins/zsh-sudo
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh -P /usr/share/zsh/plugins/zsh-sudo
pkgfile -u








cp -r ./OpenFlexOS-Configs/config/sxiv /etc/skel/.config/sxiv
cp ./OpenFlexOS-Configs/dot.xscreensaver /etc/skel/.xscreensaver
cp ./OpenFlexOS-Configs/dot.zshrc /etc/skel/.zshrc
cp ./OpenFlexOS-Configs/dot.bashrc /etc/skel/.bashrc

chmod -R +x /etc/skel/.config/$lower_main/scripts/
echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
echo "QT_AUTO_SCREEN_SCALE_FACTOR=0" >> /etc/environment
echo "QT_SCALE_FACTOR=1" >> /etc/environment
echo "QT_FONT_DPI=96" >> /etc/environment















