#!/bin/bash
# Dotfiles package installer for Shawky's i3 Setup
# Only installs what's actually needed from the dotfiles

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Installing dotfiles packages...${NC}"

# Check yay
if ! command -v yay &> /dev/null; then
    echo -e "${RED}yay not installed. Install it first.${NC}"
    exit 1
fi

# Update
echo "Updating system..."
sudo pacman -Syu --noconfirm

# ===== 1. CORE DEPENDENCIES =====
echo -e "${BLUE}Installing core dependencies...${NC}"
sudo pacman -S --needed --noconfirm \
    git curl \
    xorg-xrandr xclip xsel \
    fribidi jq bc xdotool \
    pulseaudio pavucontrol playerctl \
    network-manager-applet blueman \
    ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts noto-fonts-emoji \
    breeze breeze-gtk breeze-icons \
    fastfetch bat fzf \
    python python-pip \
    vlc

# ===== 2. I3 ESSENTIALS =====
echo -e "${BLUE}Installing i3 packages...${NC}"
sudo pacman -S --needed --noconfirm \
    i3-gaps picom rofi polybar dunst kitty xwallpaper

# ===== 3. ZSH AND SHELL TOOLS =====
echo -e "${BLUE}Installing ZSH and shell tools...${NC}"
sudo pacman -S --needed --noconfirm \
    zsh zsh-completions \
    fzf zoxide

# ===== 4. AUR PACKAGES =====
echo -e "${BLUE}Installing AUR packages...${NC}"
yay -S --needed --noconfirm \
    nerd-fonts-jetbrains-mono \
    oh-my-zsh-git \
    zsh-theme-powerlevel10k \
    visual-studio-code-bin

# ===== 5. TEXT EDITOR =====
echo -e "${BLUE}Installing text editor...${NC}"
sudo pacman -S --needed --noconfirm neovim

# ===== 6. CREATE DIRECTORIES & DOWNLOAD WALLPAPERS =====
echo -e "${BLUE}Creating necessary directories...${NC}"
mkdir -p ~/Pictures/wallpapers

echo -e "${BLUE}Downloading wallpapers from GitHub...${NC}"
# Check if wallpapers directory is empty or doesn't exist
if [ -d ~/Pictures/wallpapers ] && [ -z "$(ls -A ~/Pictures/wallpapers 2>/dev/null)" ]; then
    echo "Downloading wallpapers from Shawky-dev/wallpapers..."
    # Clone the wallpapers repo
    git clone https://github.com/Shawky-dev/wallpapers.git /tmp/wallpapers-temp
    
    # Copy all wallpapers to the wallpapers directory
    cp -r /tmp/wallpapers-temp/* ~/Pictures/wallpapers/ 2>/dev/null || true
    
    # Clean up temp directory
    rm -rf /tmp/wallpapers-temp
    
    echo "Wallpapers downloaded to ~/Pictures/wallpapers/"
else
    echo "Wallpapers directory already has content. Skipping download."
fi

# ===== 7. INSTALL ZSH PLUGINS MANUALLY =====
echo -e "${BLUE}Installing ZSH plugins...${NC}"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

# fzf-tab (for tab completion with fzf)
if [ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]; then
    echo "Installing fzf-tab..."
    git clone https://github.com/Aloxaf/fzf-tab.git $ZSH_CUSTOM/plugins/fzf-tab
fi

# ===== 8. MAKE ALL SCRIPTS EXECUTABLE =====
echo -e "${BLUE}Making all scripts executable...${NC}"

# Make polybar scripts executable
if [ -d ~/.config/polybar/scripts ]; then
    chmod +x ~/.config/polybar/scripts/*.sh 2>/dev/null || true
fi

if [ -f ~/.config/polybar/launch.sh ]; then
    chmod +x ~/.config/polybar/launch.sh
fi

# Make rofi scripts executable
if [ -d ~/.config/rofi ]; then
    find ~/.config/rofi -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
fi

# Make any other shell scripts in .config executable
find ~/.config -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# ===== 9. FINAL MESSAGE =====
echo -e "${GREEN}"
echo "================================================"
echo "INSTALLATION COMPLETE!"
echo "================================================"
echo -e "${NC}"
echo "✅ All packages installed"
echo "✅ Wallpapers downloaded from GitHub"
echo "✅ All scripts made executable"
echo ""
echo "Next steps:"
echo "1. Copy your dotfiles to ~/.config/"
echo "2. Scripts are already made executable for you"
echo "3. Wallpapers are already in ~/Pictures/wallpapers/"
echo "4. Log out and back in for ZSH to take effect"
echo "5. Run 'p10k configure' to setup Powerlevel10k theme"
echo ""
echo -e "${YELLOW}Note: After copying dotfiles, restart i3 with Mod+Shift+R${NC}"
echo -e "${YELLOW}Wallpaper repo: https://github.com/Shawky-dev/wallpapers${NC}"