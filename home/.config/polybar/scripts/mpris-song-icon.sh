#!/bin/sh
#
# Requires playerctl

declare -A ICON_MAP
ICON_MAP[default]=""
ICON_MAP[mpv]=""
ICON_MAP[vlc]="嗢"
ICON_MAP[chromium]=""
ICON_MAP[firefox]=""
ICON_MAP[qutebrowser]=""
ICON_MAP[ncspot]=""
ICON_MAP[spotify]=""

# Player priority order
play_order="ncspot spotify qutebrowser vlc mpv chromium firefox"

# Arabic RTL text formatting without extra spaces
format_metadata() {
    player="$1"
    title=$(playerctl metadata title --player="$player" 2>/dev/null)
    artist=$(playerctl metadata artist --player="$player" 2>/dev/null)
    
    # Remove any leading/trailing whitespace
    title=$(echo "$title" | xargs)
    artist=$(echo "$artist" | xargs)
    
    if [ -z "$title" ] || [ "$title" = "null" ]; then
        echo ""
        return
    fi
    
    # Format with fribidi and remove leading spaces
    if [ -z "$artist" ] || [ "$artist" = "null" ] || [ "$artist" = "" ]; then
        echo "$title" | fribidi | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
    else
        echo "$artist — $title" | fribidi | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
    fi
}

# Get icon for player
get_player_icon() {
    player="$1"
    case "${player,,}" in
        *"twitch"*)
            echo ""
            ;;
        *"youtube"*)
            echo ""
            ;;
        *)
            PLAYER_ICON="${ICON_MAP[${player}]}"
            [ -z "$PLAYER_ICON" ] && PLAYER_ICON="${ICON_MAP[default]}"
            echo "$PLAYER_ICON"
            ;;
    esac
}

# Main execution
for player in $play_order; do
    if [ "$(playerctl status --player="$player" 2>/dev/null)" = "Playing" ]; then
        formatted_text=$(format_metadata "$player")
        
        if [ -n "$formatted_text" ]; then
            icon=$(get_player_icon "$player")
            # Remove any extra spaces between icon and text
            echo "${icon}${formatted_text}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
        fi
        exit 0
    fi
done

# No player is playing
echo ""