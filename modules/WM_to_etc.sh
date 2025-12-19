while getopts 'QO' configs; do
	case $configs in
		Q )
			cp -r ./OpenFlexOS-Configs/home/user/config/qtile /etc/openflexos/home/users/config/qtile
			;;
		O )
			cp -r ./OpenFlexOS-Configs/home/user/config/openbox /etc/openflexos/home/users/config/openbox
			;;
	esac
done

