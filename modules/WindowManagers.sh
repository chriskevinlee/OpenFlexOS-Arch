while getopts 'QO' configs; do
case $configs in
	Q )
		pacman --noconfirm --needed -S qtile
		rm /usr/share/wayland-sessions/qtile-wayland.desktop
		;;
	O )
		pacman --noconfirm --needed -S openbox
		pacman --noconfirm --needed -S tint2

		# Install and configure obmenu-generator
		pacman -Sy --noconfirm perl perl-gtk3 perl-data-dump base-devel git sudo

		# Create builder user if not exists
		id builder &>/dev/null || useradd -m builder
		passwd -d builder || true
		usermod -aG wheel builder

		echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
		chmod 440 /etc/sudoers.d/builder

		su - builder -c "
		  cd ~
		  git clone https://aur.archlinux.org/perl-linux-desktopfiles.git
		  cd perl-linux-desktopfiles
		  makepkg -si --noconfirm
		"
		git clone https://github.com/trizen/obmenu-generator.git /tmp/obmenu-generator
		cp /tmp/obmenu-generator/schema.pl /etc/openflexos/home/users/config/obmenu-generator/
		cp /tmp/obmenu-generator/obmenu-generator /usr/local/bin/
		chmod +x /usr/local/bin/obmenu-generator

		# (Optional) Clean up builder user and temp files
		 userdel -r builder
		 rm -rf /tmp/obmenu-generator
		;;
esac
done