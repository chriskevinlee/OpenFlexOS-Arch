#!/bin/bash
clear

echo "OpenFlexOS has a repository containing all config files. If yes is selected, the OpenFlexOS repository will be added to pacman.conf and you will receive updated configs.
If no is selected, the configs will be downloaded and copied manually, and you will not receive updates."
read -p "Would you like to use the repository? [y/n]: " yn

case "${yn,,}" in
  y|yes)
    if grep -q "^\[openflexos\]" /etc/pacman.conf; then
      echo "✅ OpenFlexOS repository already exists in pacman.conf — skipping addition."
    else
      echo "🛠 Adding OpenFlexOS repository to /etc/pacman.conf..."
      sudo bash -c 'cat >> /etc/pacman.conf <<EOF

[openflexos]
SigLevel = Optional TrustAll
Server = https://chriskevinlee.github.io/TestRepo-OpenFlexOS-Packages/
EOF'
      echo "✅ Repository added successfully."
    fi

    echo "🔄 Updating package database..."
    sudo pacman -Syy
    ;;
  n|no)
    echo "📁 Copying configs manually..."
    # Add your config copy commands here
    ;;
  *)
    echo "⚠️ Invalid response. Please enter y or n."
    ;;
esac