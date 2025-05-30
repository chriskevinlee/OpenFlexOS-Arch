while getopts 'QBO' configs; do
case $configs in
	Q )
        
		pacman --noconfirm --needed -S qtile
		rm /usr/share/wayland-sessions/qtile-wayland.desktop
		;;
esac


done