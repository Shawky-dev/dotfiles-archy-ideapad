#!/usr/bin/env bash

set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

log() {
  echo -e "${CYAN}[+]${RESET} $1"
}

warn() {
  echo -e "${YELLOW}[!]${RESET} $1"
}

error() {
  echo -e "${RED}[-] $1${RESET}"
}

success() {
  echo -e "${GREEN}[✓] $1${RESET}"
}

header() {
  echo -e "\n${MAGENTA}${BOLD}=== $1 ===${RESET}\n"
}

# --- Whale ASCII ---
whale() {
  echo -e "${BLUE}"
  cat << "EOF"
        .
       ":"
     ___:____     |"\/"|
   ,'        `.    \  /
   |  O        \___/  |
 ~^~^~^~^~^~^~^~^~^~^~^~^~
EOF
  echo -e "${RESET}"
}

# --- Start ---
whale
header "Docker Full Reset"

warn "This will COMPLETELY wipe Docker:"
echo -e "  ${RED}- Containers${RESET}"
echo -e "  ${RED}- Images${RESET}"
echo -e "  ${RED}- Volumes (DATA LOSS)${RESET}"
echo -e "  ${RED}- Networks${RESET}"
echo -e "  ${RED}- Cache${RESET}"

echo
read -rp "$(echo -e ${YELLOW}Type 'YES' to continue:${RESET} ) " confirm

if [[ "$confirm" != "YES" ]]; then
  error "Aborted by user."
  exit 0
fi

# --- Stop Services ---
header "Stopping Services"

log "Stopping Docker service..."
sudo systemctl stop docker docker.socket 2>/dev/null || true

log "Stopping containerd service..."
sudo systemctl stop containerd 2>/dev/null || true

# --- Wipe Data ---
header "Wiping Data"

log "Removing /var/lib/docker..."
sudo rm -rf /var/lib/docker

log "Removing /var/lib/containerd..."
sudo rm -rf /var/lib/containerd

# --- Restart in correct order ---
header "Restarting Services"

log "Starting containerd first..."
sudo systemctl start containerd

log "Waiting for containerd to initialize..."
sleep 2

log "Starting Docker service..."
sudo systemctl start docker

# --- Verification ---
header "Verification"

log "Checking containerd snapshotter directory..."
if [[ -d /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots ]]; then
  success "Containerd snapshotter directory exists."
else
  warn "Snapshotter dir not yet created (will be created on first use — this is OK)."
fi

log "Checking Docker status..."
if docker info > /dev/null 2>&1; then
  success "Docker is running and clean."
else
  error "Docker failed to start properly. Check: sudo systemctl status docker"
  exit 1
fi

header "Complete"
success "Docker has been fully reset to a pristine state."