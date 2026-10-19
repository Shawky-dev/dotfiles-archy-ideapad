#!/usr/bin/env bash

## Rofi : Scripts Menu (uses the power-modes menu theme)
#
## Enter        run the script in the background
## Shift+Enter  run the script in a terminal (for interactive ones)
## Ctrl+Enter   type arguments before running
#
## Scripts can offer argument choices with a header line, e.g.:
##   # rofi-args: left|right

# Theme (same as power-modes menu)
theme="$HOME/.config/rofi/themes/menu.rasi"

# Directories to search for executable scripts: "path:maxdepth"
search_dirs=(
	"$HOME/scripts:2"
	"$HOME/.config/rofi/scripts:1"
)

self="$(realpath "$0")"

# Collect executables as "name<TAB>dir<TAB>path", skipping binaries and this script
list_scripts() {
	for entry in "${search_dirs[@]}"; do
		d="${entry%:*}"; depth="${entry##*:}"
		[[ -d "$d" ]] || continue
		find -L "$d" -maxdepth "$depth" -type f -perm -u+x \
			-not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null |
		while read -r f; do
			[[ "$(realpath "$f")" == "$self" ]] && continue
			head -c2 "$f" | grep -q '#!' || continue
			d="$(dirname "$f")"
			printf '%-26s\t%s\t%s\n' "$(basename "$f")" "${d/#$HOME/\~}" "$f"
		done
	done | sort -u
}

# Rofi CMD
rofi_cmd() {
	rofi -dmenu -i \
		-p 'Scripts >' \
		-display-columns 1,2 -display-column-separator $'\t' \
		-kb-accept-alt '' -kb-accept-custom '' \
		-kb-custom-1 'Shift+Return' -kb-custom-2 'Control+Return' \
		-theme-str 'window {width: 600px;}' \
		-theme "$theme"
}

# Ask for arguments: offer the script's "# rofi-args:" choices, or free text
ask_args() {
	local choices
	choices="$(grep -m1 -oP '^#\s*rofi-args:\s*\K.*' "$1" | tr '|' '\n' | sed 's/^ *//;s/ *$//')"
	printf '%s' "$choices" | rofi -dmenu -i \
		-p "$(basename "$1") >" \
		-theme-str 'entry {placeholder: "type arguments...";}' \
		-theme "$theme"
}

chosen="$(list_scripts | rofi_cmd)"
code=$?
[[ -z "$chosen" ]] && exit 0

path="${chosen##*$'\t'}"

# Get arguments if the script declares choices or Ctrl+Enter was used
args=()
if [[ $code -eq 11 ]] || grep -qE '^#\s*rofi-args:' "$path"; then
	input="$(ask_args "$path")" || exit 0
	read -ra args <<< "$input"
fi

case $code in
	10) setsid -f kitty --hold "$path" "${args[@]}" >/dev/null 2>&1 ;;
	*)  setsid -f "$path" "${args[@]}" >/dev/null 2>&1 ;;
esac
