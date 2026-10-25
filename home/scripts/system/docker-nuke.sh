#!/usr/bin/env bash

set -euo pipefail

# ── Colors & Styles ────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

RED="\033[38;5;196m"
ORANGE="\033[38;5;208m"
YELLOW="\033[38;5;226m"
GREEN="\033[38;5;46m"
CYAN="\033[38;5;51m"
PURPLE="\033[38;5;135m"
WHITE="\033[97m"

BG_DARK="\033[48;5;232m"

# ── Helpers ────────────────────────────────────────────────────────────────────
twidth() { tput cols 2>/dev/null || echo 80; }

println() { echo -e "$1"; }
newline()  { echo; }

divider() {
  local w; w=$(twidth)
  local char="${1:-─}"
  local color="${2:-$DIM}"
  printf "${color}"
  printf '%*s' "$w" '' | tr ' ' "$char"
  printf "${RESET}\n"
}

center() {
  local text="$1"
  local color="${2:-$WHITE}"
  local w; w=$(twidth)
  local clean; clean=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
  local len=${#clean}
  local pad=$(( (w - len) / 2 ))
  printf "%${pad}s" ""
  echo -e "${color}${text}${RESET}"
}

step() {
  local num="$1"
  local label="$2"
  echo -e "\n ${DIM}${num}${RESET}  ${BOLD}${WHITE}${label}${RESET}"
}

log()     { echo -e "   ${CYAN}›${RESET} $1"; }
success() { echo -e "   ${GREEN}✔${RESET}  ${GREEN}$1${RESET}"; }
warn()    { echo -e "   ${YELLOW}⚠${RESET}  ${YELLOW}$1${RESET}"; }
fail()    { echo -e "   ${RED}✘${RESET}  ${RED}${BOLD}$1${RESET}"; }

# ── Spinner ────────────────────────────────────────────────────────────────────
spinner_pid=""

spinner_start() {
  local label="${1:-Working...}"
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  (
    local i=0
    while true; do
      printf "\r   ${CYAN}${frames[$i]}${RESET}  ${DIM}${label}${RESET}  "
      i=$(( (i + 1) % ${#frames[@]} ))
      sleep 0.08
    done
  ) &
  spinner_pid=$!
  disown "$spinner_pid" 2>/dev/null || true
}

spinner_stop() {
  if [[ -n "$spinner_pid" ]]; then
    kill "$spinner_pid" 2>/dev/null || true
    wait "$spinner_pid" 2>/dev/null || true
    spinner_pid=""
    printf "\r\033[K"
  fi
}

# ── Progress Bar ───────────────────────────────────────────────────────────────
progress() {
  local label="$1"
  local duration="${2:-1.2}"
  local w=32
  local delay; delay=$(echo "scale=4; $duration / $w" | bc)

  printf "   ${DIM}${label}${RESET}\n   ["
  for ((i=0; i<w; i++)); do
    local pct=$(( (i * 100) / w ))
    if   (( pct < 40 )); then printf "${RED}█${RESET}"
    elif (( pct < 75 )); then printf "${YELLOW}█${RESET}"
    else                      printf "${GREEN}█${RESET}"
    fi
    sleep "$delay"
  done
  printf "${DIM}]${RESET} ${GREEN}done${RESET}\n"
}

# ── Banner ─────────────────────────────────────────────────────────────────────
banner() {
  newline
  divider "═" "$PURPLE"
  newline
  center "${RED}${BOLD}██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗ "
  center "${RED}${BOLD}██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗"
  center "${ORANGE}${BOLD}██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝"
  center "${ORANGE}${BOLD}██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗"
  center "${YELLOW}${BOLD}██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║"
  center "${YELLOW}${BOLD}╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
  newline
  center "${DIM}full system wipe  ·  use with intent${RESET}"
  newline
  divider "═" "$PURPLE"
  newline
}

# ── Warning Screen ─────────────────────────────────────────────────────────────
warning_screen() {
  newline
  center "${RED}${BOLD}⚠  DESTRUCTIVE OPERATION  ⚠"
  newline

  local w; w=$(twidth)
  local box_w=50
  local pad=$(( (w - box_w) / 2 ))
  local sp; sp=$(printf "%${pad}s" "")

  println "${sp}${DIM}┌────────────────────────────────────────────────┐${RESET}"
  println "${sp}${DIM}│${RESET}   The following will be ${RED}${BOLD}permanently deleted${RESET}:   ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}                                                ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}   ${RED}✘${RESET}  All containers (running & stopped)        ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}   ${RED}✘${RESET}  All images                                ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}   ${RED}✘${RESET}  All volumes ${BOLD}(DATA LOSS)${RESET}                 ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}   ${RED}✘${RESET}  All networks                              ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}   ${RED}✘${RESET}  Build cache                               ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}   ${RED}✘${RESET}  /var/lib/docker                           ${DIM}│${RESET}"
  println "${sp}${DIM}│${RESET}   ${RED}✘${RESET}  /var/lib/containerd                       ${DIM}│${RESET}"
  println "${sp}${DIM}└────────────────────────────────────────────────┘${RESET}"
  newline
  divider
  newline
}

# ── Main ───────────────────────────────────────────────────────────────────────
banner
warning_screen

printf "   ${YELLOW}${BOLD}Type 'YES' to proceed:${RESET}  "
read -r confirm
newline

if [[ "$confirm" != "YES" ]]; then
  center "${DIM}Aborted. Nothing was touched.${RESET}"
  newline
  exit 0
fi

# Warm up sudo credentials before any spinners start so the password
# prompt doesn't collide with animated terminal output
echo -e "\n   ${DIM}sudo required — enter your password below${RESET}"
sudo -v

divider

# ── 01: Stop Services ──────────────────────────────────────────────────────────
step "01" "Stopping Services"
newline

spinner_start "Stopping docker.socket..."
sudo systemctl stop docker.socket 2>/dev/null || true
spinner_stop
success "docker.socket stopped"

spinner_start "Stopping docker daemon..."
sudo systemctl stop docker 2>/dev/null || true
spinner_stop
success "docker stopped"

spinner_start "Stopping containerd..."
sudo systemctl stop containerd 2>/dev/null || true
spinner_stop
success "containerd stopped"

# ── 02: Wipe ───────────────────────────────────────────────────────────────────
newline
step "02" "Wiping Data"
newline

progress "Removing /var/lib/docker" 1.4
sudo rm -rf /var/lib/docker
success "/var/lib/docker removed"

progress "Removing /var/lib/containerd" 0.9
sudo rm -rf /var/lib/containerd
success "/var/lib/containerd removed"

# ── 03: Restart ────────────────────────────────────────────────────────────────
newline
step "03" "Restarting Services"
newline

spinner_start "Starting containerd..."
sudo systemctl start containerd
spinner_stop
success "containerd started"

spinner_start "Waiting for containerd to initialize..."
sleep 2
spinner_stop
success "containerd initialized"

spinner_start "Starting docker..."
sudo systemctl start docker
spinner_stop
success "docker started"

# ── 04: Verify ─────────────────────────────────────────────────────────────────
newline
step "04" "Verification"
newline

SNAPSHOTS_DIR="/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots"
if [[ -d "$SNAPSHOTS_DIR" ]]; then
  success "Containerd snapshotter directory present"
else
  warn "Snapshotter dir not yet created (normal — created on first use)"
fi

if docker info > /dev/null 2>&1; then
  success "Docker is running"
else
  fail "Docker failed to start — run: sudo systemctl status docker"
  newline
  exit 1
fi

# ── Done ───────────────────────────────────────────────────────────────────────
newline
divider "═" "$GREEN"
newline
center "${GREEN}${BOLD}All done. Docker is clean and ready."
newline
divider "═" "$GREEN"
newline
