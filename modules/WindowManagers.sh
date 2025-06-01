while getopts 'QO' configs; do
case $configs in
	Q )
		pacman --noconfirm --needed -S qtile
		rm /usr/share/wayland-sessions/qtile-wayland.desktop
		;;
	O )
		pacman --noconfirm --needed -S openbox
		pacman --noconfirm --needed -S tint2
		;;
esac


done