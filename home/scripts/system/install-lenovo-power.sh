#!/usr/bin/env bash
# Installs the Lenovo power helper as root-owned and allows running it via sudo without a password.
# Run with: sudo bash ~/dotfiles/home/scripts/system/install-lenovo-power.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }

user="${SUDO_USER:?run via sudo}"
src="$(dirname "$(readlink -f "$0")")/lenovo-power.sh"

install -o root -g root -m 755 "$src" /usr/local/bin/lenovo-power

rule="/etc/sudoers.d/lenovo-power"
tmp="$(mktemp)"
echo "$user ALL=(root) NOPASSWD: /usr/local/bin/lenovo-power" > "$tmp"
visudo -cf "$tmp"
install -o root -g root -m 440 "$tmp" "$rule"
rm -f "$tmp"

echo "Done. Test: sudo -n /usr/local/bin/lenovo-power get-conservation"
