while getopts 'QO' configs; do
case $configs in
	Q )
		pacman --noconfirm --needed -S qtile
		rm /usr/share/wayland-sessions/qtile-wayland.desktop
		PKG=qtile-extras

		BUILD_USER=_aurbuilder
		BUILD_HOME=/tmp/${BUILD_USER}-home
		BUILD_DIR=/tmp/${PKG}-build

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
		cp /tmp/obmenu-generator/obmenu-generator /usr/local/bin/
		chmod +x /usr/local/bin/obmenu-generator

		# (Optional) Clean up builder user and temp files
		 userdel -r builder
		 rm -rf /tmp/obmenu-generator
		;;
esac
done
