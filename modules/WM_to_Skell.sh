mkdir /etc/skel/.config
mkdir /etc/skel/.config/wallpapers
git clone https://github.com/chriskevinlee/wallpaper_cave_nature.git /etc/skel/.config/wallpapers/wallpaper_cave_nature/

while getopts 'QO' configs; do
case $configs in
	Q )
		cp -r ./OpenFlexOS-Configs/config/qtile /etc/skel/.config/qtile/
		;;
	O )
		cp -r ./OpenFlexOS-Configs/config/openbox /etc/skel/.config/openbox/
		;;
esac


done

