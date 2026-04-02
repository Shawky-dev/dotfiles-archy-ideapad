#!/bin/bash
#
# mpris-song-tail.sh -- tail script for polybar custom/script
# Follows playerctl metadata changes so the song name updates on track changes.
#
# Requires: playerctl

declare -A ICON_MAP=(
    [default]=""
    [mpv]=""
    [vlc]="嗢"
    [chromium]=""
    [firefox]=""
    [qutebrowser]=""
    [ncspot]=""
    [spotify]=""
)

get_icon() {
    local player="$1"
    case "${player,,}" in
        *twitch*)
            echo ""
            ;;
        *youtube*)
            echo ""
            ;;
        *)
            local icon="${ICON_MAP[$player]}"
            echo "${icon:-${ICON_MAP[default]}}"
            ;;
    esac
}

format_output() {
    local player title artist formatted icon

    player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null) || return
    [[ -z "$player" ]] && return

    title=$(playerctl metadata title 2>/dev/null)
    artist=$(playerctl metadata artist 2>/dev/null)

    [[ -z "$title" || "$title" == "null" ]] && return

    if [[ -n "$artist" && "$artist" != "null" ]]; then
        formatted="$artist -- $title"
    else
        formatted="$title"
    fi

    if command -v fribidi >/dev/null 2>&1; then
        formatted=$(echo "$formatted" | fribidi | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi

    icon=$(get_icon "$player")
    echo "${icon}${formatted}"
}

format_output

playerctl metadata --follow --format '{{playerName}}|{{status}}|{{title}}|{{artist}}' 2>/dev/null | while IFS='|' read -r _pname status _title _artist; do
    if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
        format_output
    else
        echo ""
    fi
done
