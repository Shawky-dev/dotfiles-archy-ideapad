#!/usr/bin/env bash

set -e

# Packages to install
PACKAGES=(
    base-devel
    cmake
    make
    curl
    wget
    kitty
)

# Update system
sudo pacman -Syu --noconfirm

# Install packages
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# Install yay if missing
if ! command -v yay >/dev/null 2>&1; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
fi

echo "Done."
