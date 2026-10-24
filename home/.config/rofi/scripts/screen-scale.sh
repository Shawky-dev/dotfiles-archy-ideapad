#!/usr/bin/env bash

## Rofi : Per-screen zoom for X11/i3
#
## X11 only has one global DPI, so per-screen scaling is done with an xrandr
## transform: the screen shows a smaller desktop area, upscaled. Content gets
## bigger (slightly softer); other screens keep their native resolution and
## are only moved so nothing overlaps.
#
## Usage: screen-scale.sh          open the menu
##        screen-scale.sh apply    re-apply saved zoom levels (used by monitor-layout.sh)

theme="$HOME/.config/rofi/themes/menu.rasi"
state="${XDG_STATE_HOME:-$HOME/.local/state}/screen-scale"
step=10
presets=(100 110 125 150 175 200)

# Active outputs as "name modeW modeH mmW mmH x"
outputs() {
	xrandr --query | awk '
		/ connected/ {
			name = ""
			if (match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/)) {
				split(substr($0, RSTART, RLENGTH), g, /[x+]/)
				name = $1; x = g[3]; mmw = $(NF-2); mmh = $NF
				sub(/mm/, "", mmw); sub(/mm/, "", mmh)
			}
			next
		}
		/ disconnected/ { name = ""; next }
		name && /\*/ { split($1, m, "x"); print name, m[1], m[2], mmw, mmh, x; name = "" }
	' | sort -k6 -n
}

zoom_of() {
	local z
	z="$(awk -v n="$1" '$1 == n {print $2}' "$state" 2>/dev/null)"
	echo "${z:-100}"
}

# Lay out all screens left-to-right (current order) with their saved zoom
apply() {
	local args=() x=0 name w h mmw mmh pos z lw lh
	while read -r name w h mmw mmh pos; do
		z="$(zoom_of "$name")"
		lw=$(( (w * 100 + z / 2) / z ))
		lh=$(( (h * 100 + z / 2) / z ))
		if (( z == 100 )); then
			args+=(--output "$name" --scale 1x1 --pos "${x}x0")
		else
			args+=(--output "$name" --scale-from "${lw}x${lh}" --pos "${x}x0")
		fi
		x=$(( x + lw ))
	done < <(outputs)
	(( ${#args[@]} )) && xrandr "${args[@]}"
}

set_zoom() {
	local z=$2
	(( z < 50 )) && z=50
	(( z > 300 )) && z=300
	mkdir -p "$(dirname "$state")"
	{ grep -v "^$1 " "$state" 2>/dev/null; (( z != 100 )) && echo "$1 $z"; } > "$state.tmp"
	mv "$state.tmp" "$state"
	apply
	reload
}

reload() {
	setsid -f "$HOME/.config/polybar/launch.sh" >/dev/null 2>&1
}

# Adjust one screen; stays open so you can keep pressing Bigger/Smaller
screen_menu() {
	local name=$1 row=0 w h mmw mmh z o ow oh omw omh pos labels actions i
	read -r _ w h mmw mmh _ < <(outputs | awk -v n="$name" '$1 == n')
	while :; do
		z="$(zoom_of "$name")"
		labels=("  Bigger  (+$step%)" "  Smaller (-$step%)")
		actions=($(( z + step )) $(( z - step )))
		# Zoom that makes this screen's text the same physical size as another's
		while read -r o ow oh omw omh pos; do
			[[ $o == "$name" ]] && continue
			(( mmw > 0 && omw > 0 )) || continue
			i=$(( (w * omw * 100 + mmw * ow / 2) / (mmw * ow) ))
			labels+=("󰹑  Match $o size  ($i%)"); actions+=("$i")
		done < <(outputs)
		for i in "${presets[@]}"; do
			labels+=("󰍉  $i%$( (( i == z )) && echo '  (current)')"); actions+=("$i")
		done
		labels+=("  Back"); actions+=(back)

		row="$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -format i \
			-selected-row "$row" -no-custom \
			-p "󰍹  $name · $z%" -theme "$theme")" || exit 0
		[[ ${actions[row]} == back ]] && return
		set_zoom "$name" "${actions[row]}"
	done
}

main_menu() {
	local names labels choice name w h mmw mmh pos
	while :; do
		names=(); labels=()
		while read -r name w h mmw mmh pos; do
			names+=("$name")
			labels+=("󰍹  $name   ${w}x${h}   zoom $(zoom_of "$name")%")
		done < <(outputs)
		labels+=("󰑓  Reset all to 100%")

		choice="$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -format i -no-custom \
			-p "󰍹  Screen scale" -theme "$theme")" || exit 0
		if (( choice == ${#names[@]} )); then
			rm -f "$state"
			apply
			reload
		else
			screen_menu "${names[choice]}"
		fi
	done
}

case "$1" in
	apply)     apply ;;
	""|menu)   main_menu ;;
	*)         echo "usage: $0 [menu|apply]" >&2; exit 1 ;;
esac
