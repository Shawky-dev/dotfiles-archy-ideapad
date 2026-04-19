#!/usr/bin/env bash

# Minimal bootstrap for a fresh Arch install.
# Installs the tooling needed to run the main dotfiles installer, then hands off
# to setup.sh so the package list only lives in one place.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git curl wget

if ! command -v yay >/dev/null 2>&1; then
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
fi

exec "$ROOT_DIR/setup.sh"
