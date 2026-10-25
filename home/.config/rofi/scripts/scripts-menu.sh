#!/usr/bin/env bash

## Rofi : Scripts Menu (uses the power-modes menu theme)
#
## Opens on your script folders; pick one to see its scripts.
## Esc (or "..") goes back up a level.
#
## Enter        open a folder / run the script in the background
## Shift+Enter  run the script in a terminal (for interactive ones)
## Ctrl+Enter   type arguments before running
#
## Scripts can offer argument choices with a header line, e.g.:
##   # rofi-args: left|right

# Theme (same as power-modes menu)
theme="$HOME/.config/rofi/themes/menu.rasi"

# Each subfolder of ~/scripts is a menu folder; loose scripts show at the top
scripts_root="$HOME/scripts"
# Extra folders shown alongside them: "label:path"
extra_dirs=(
	"rofi:$HOME/.config/rofi/scripts"
)

self="$(realpath "$0")"

# Executables in folder $1 as "label<TAB>$2<TAB>path", skipping binaries and this script
list_scripts() {
	find -L "$1" -maxdepth 1 -type f -perm -u+x 2>/dev/null | sort |
	while read -r f; do
		[[ "$(realpath "$f")" == "$self" ]] && continue
		head -c2 "$f" | grep -q '#!' || continue
		printf '%-30s\t%s\t%s\n' "󰆍  $(basename "$f")" "$2" "$f"
	done
}

# One folder entry, or nothing if it holds no scripts
folder_entry() {
	local n
	n="$(list_scripts "$2" | wc -l)"
	(( n )) && printf '%-30s\t%s scripts\t%s\n' "󰉋  $1" "$n" "$2"
}

# "label:path" for every folder: subfolders of ~/scripts, then extra_dirs
all_dirs() {
	local d
	for d in "$scripts_root"/*/; do
		echo "$(basename "$d"):${d%/}"
	done
	printf '%s\n' "${extra_dirs[@]}"
}

# Top level: folders first, then loose scripts, then every folder's scripts
# (tagged with their folder) so a search matches both, folders listed first
top_entries() {
	local entry
	while read -r entry; do
		folder_entry "${entry%%:*}" "${entry#*:}"
	done < <(all_dirs)
	list_scripts "$scripts_root"
	while read -r entry; do
		list_scripts "${entry#*:}" "${entry%%:*}"
	done < <(all_dirs)
}

# Rofi CMD
rofi_cmd() {
	rofi -dmenu -i -no-custom \
		-p "$1" \
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

# Browse: an empty $dir is the top level
dir=""
while :; do
	if [[ -z "$dir" ]]; then
		chosen="$(top_entries | rofi_cmd '󰆍  Scripts')"
	else
		chosen="$( { printf '%-30s\tback\t..\n' '󰁍  ..'; list_scripts "$dir"; } |
			rofi_cmd "󰉋  $(basename "$dir")")"
	fi
	code=$?

	if [[ -z "$chosen" ]]; then
		[[ -n "$dir" ]] && { dir=""; continue; }
		exit 0
	fi

	path="${chosen##*$'\t'}"
	if [[ "$path" == ".." ]]; then dir=""
	elif [[ -d "$path" ]]; then dir="$path"
	else break
	fi
done

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
