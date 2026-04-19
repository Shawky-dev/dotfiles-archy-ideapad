#!/usr/bin/env bash

# Dotfiles installer for Shawky's Arch + i3 setup.
# Installs packages actually referenced by the repo, optional AUR extras,
# fonts used by the active themes, wallpapers, and executable bits.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PACMAN_PACKAGES=(
    base-devel
    git
    curl
    wget
    unzip
    bc
    jq
    fribidi
    xclip
    xsel
    xdotool
    xorg-xhost
    xorg-xrandr
    xorg-setxkbmap
    dex
    xss-lock
    gnome-keyring
    pipewire-pulse
    pavucontrol
    playerctl
    polkit-gnome
    network-manager-applet
    blueman
    bluez-utils
    i3-wm
    picom
    rofi
    polybar
    dunst
    kitty
    xwallpaper
    zsh
    zsh-completions
    zoxide
    fzf
    fastfetch
    bat
    neovim
    python
    python-pip
    pkgfile
    xdg-user-dirs
    viewnior
    brightnessctl
    flameshot
    maim
    tesseract
    tesseract-data-eng
    ffmpeg
    zathura
    vlc
    acpi
    acpi_call
    cpupower
    tlp
    tlp-rdw
    mpc
    mpd
    docker
    x11vnc
    ttf-iosevka-nerd
    ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols
    noto-fonts
    noto-fonts-extra
    noto-fonts-emoji
    breeze
    breeze-gtk
    breeze-icons
)

REQUIRED_AUR_PACKAGES=(
    greenclip
    i3lock-color
    betterlockscreen
    oh-my-zsh-git
    zsh-theme-powerlevel10k
    visual-studio-code-bin
    blueberry
    optimus-manager-git
)

OPTIONAL_AUR_PACKAGES=(
    caffeine-ng
    ttf-feather
    ttf-grape-nuts
)

print_section() {
    echo -e "${BLUE}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

ensure_yay() {
    if command -v yay >/dev/null 2>&1; then
        return
    fi

    print_section "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git

    local build_dir="/tmp/yay"
    rm -rf "$build_dir"
    git clone https://aur.archlinux.org/yay.git "$build_dir"
    (
        cd "$build_dir"
        makepkg -si --noconfirm
    )
}

install_pacman_packages() {
    print_section "Updating system..."
    sudo pacman -Syu --noconfirm

    print_section "Installing official repo packages..."
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

install_aur_packages() {
    print_section "Installing required AUR packages..."
    yay -S --needed --noconfirm "${REQUIRED_AUR_PACKAGES[@]}"

    print_section "Installing optional AUR packages when available..."
    local pkg
    for pkg in "${OPTIONAL_AUR_PACKAGES[@]}"; do
        if yay -S --needed --noconfirm "$pkg"; then
            :
        else
            warn "Skipping optional AUR package: $pkg"
        fi
    done
}

prepare_zsh_layout() {
    print_section "Preparing Oh My Zsh layout..."

    if [ ! -e "$HOME/.oh-my-zsh" ] && [ -d /usr/share/oh-my-zsh ]; then
        ln -s /usr/share/oh-my-zsh "$HOME/.oh-my-zsh"
    fi

    local zsh_custom="$HOME/.oh-my-zsh/custom"
    mkdir -p "$zsh_custom/plugins"

    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ] && [ -d /usr/share/oh-my-zsh ]; then
        warn "~/.oh-my-zsh exists without the core files; using /usr/share/oh-my-zsh and keeping custom plugins in ~/.oh-my-zsh/custom."
    fi

    if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$zsh_custom/plugins/zsh-syntax-highlighting"
    fi

    if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "$zsh_custom/plugins/zsh-autosuggestions"
    fi

    if [ ! -d "$zsh_custom/plugins/fzf-tab" ]; then
        git clone https://github.com/Aloxaf/fzf-tab.git \
            "$zsh_custom/plugins/fzf-tab"
    fi
}

prepare_directories() {
    print_section "Creating runtime directories..."

    mkdir -p \
        "$HOME/Pictures/wallpapers" \
        "$HOME/Pictures/Screenshots" \
        "$HOME/Pictures/OCR" \
        "$HOME/.local/share/cheatsheets"

    xdg-user-dirs-update || true
    fc-cache -fv >/dev/null 2>&1 || true
}

download_wallpapers() {
    print_section "Downloading wallpapers if needed..."

    if [ -d "$HOME/Pictures/wallpapers" ] && [ -n "$(ls -A "$HOME/Pictures/wallpapers" 2>/dev/null)" ]; then
        echo "Wallpaper directory already has content. Skipping download."
        return
    fi

    local tmp_dir="/tmp/wallpapers-temp"
    rm -rf "$tmp_dir"
    git clone https://github.com/Shawky-dev/wallpapers.git "$tmp_dir"
    cp -r "$tmp_dir"/. "$HOME/Pictures/wallpapers/"
    rm -rf "$tmp_dir"

    echo "Wallpapers downloaded to $HOME/Pictures/wallpapers/"
}

update_lockscreen() {
    if ! command -v betterlockscreen >/dev/null 2>&1; then
        return
    fi

    local lock_img="$HOME/Pictures/wallpapers/Nighthawks.png"
    if [ -f "$lock_img" ]; then
        print_section "Updating betterlockscreen background..."
        betterlockscreen -u "$lock_img"
    else
        warn "Lockscreen image not found at $lock_img"
    fi
}

chmod_repo_scripts() {
    print_section "Making repo scripts executable..."

    find "$ROOT_DIR" -type f \
        \( -name "*.sh" -o -path "*/scripts/*" \) \
        -exec chmod +x {} +
}

chmod_deployed_scripts() {
    print_section "Making deployed scripts executable when present..."

    if [ -d "$HOME/.config" ]; then
        find "$HOME/.config" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    fi

    if [ -d "$HOME/scripts" ]; then
        find "$HOME/scripts" -type f -exec chmod +x {} + 2>/dev/null || true
    fi
}

set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ -z "$zsh_path" ]; then
        warn "zsh is not installed; skipping default shell change."
        return
    fi

    if [ "${SHELL:-}" = "$zsh_path" ]; then
        echo "Default shell is already set to zsh."
        return
    fi

    print_section "Setting zsh as the default shell..."
    chsh -s "$zsh_path" "$USER"
}

print_summary() {
    echo -e "${GREEN}"
    echo "================================================"
    echo "INSTALLATION COMPLETE"
    echo "================================================"
    echo -e "${NC}"
    echo "Installed packages used by the i3, polybar, rofi, zsh, and helper scripts."
    echo "Installed the main Nerd Fonts and Noto fonts referenced by the repo."
    echo "Ensured script execute bits are set in both the repo and deployed config paths."
    echo
    echo "Next steps:"
    echo "1. Copy or stow the dotfiles from $ROOT_DIR/home into \$HOME."
    echo "2. Log out and back in so the shell, fonts, and desktop services fully refresh."
    echo "3. Run 'p10k configure' if you want to regenerate your prompt."
    echo
    warn "Optional theme fonts such as feather/Grape Nuts are attempted from AUR and may be skipped if unavailable."
}

echo -e "${GREEN}Installing dotfiles packages and runtime dependencies...${NC}"

ensure_yay
install_pacman_packages
install_aur_packages
prepare_zsh_layout
prepare_directories
download_wallpapers
update_lockscreen
chmod_repo_scripts
chmod_deployed_scripts
set_default_shell
print_summary
