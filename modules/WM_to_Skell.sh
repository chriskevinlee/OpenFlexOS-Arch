mkdir /etc/skel/.config
mkdir /etc/skel/.config/wallpapers
git clone https://github.com/chriskevinlee/wallpaper_cave_nature.git /etc/skel/.config/wallpapers/wallpaper_cave_nature/
#git clone https://github.com/chriskevinlee/OpenFlexOS-Configs.git ./OpenFlexOS-Configs

while getopts 'QBO' configs; do
case $configs in
	Q )
		cp -r ./OpenFlexOS-Configs/config/qtile /etc/skel/.config/qtile/
		;;
esac


done

