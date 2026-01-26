#!/bin/sh
#
# Updates checker with dunst notifications

UPDATE_FILE_TMP="/tmp/polybar_updates"
[ ! -f "$UPDATE_FILE_TMP" ] && echo "0" > "$UPDATE_FILE_TMP"

# Get updates count
ARCH_UPDATES=$(checkupdates 2>/dev/null | wc -l)
AUR_UPDATES=$(yay -Qum 2>/dev/null | wc -l)

# Default to 0 if empty
[ -z "$ARCH_UPDATES" ] && ARCH_UPDATES=0
[ -z "$AUR_UPDATES" ] && AUR_UPDATES=0

TOTAL_UPDATES=$((ARCH_UPDATES + AUR_UPDATES))

# Read previous count
PREVIOUS_COUNT=$(cat "$UPDATE_FILE_TMP" 2>/dev/null || echo "0")

# Show notification if new updates are available
if [ "$TOTAL_UPDATES" -gt "$PREVIOUS_COUNT" ] 2>/dev/null; then
    # Using notify-send (works with dunst)
    notify-send -i "system-software-update" \
        "📦 Software Updates Available" \
        "There are $TOTAL_UPDATES updates ($ARCH_UPDATES Arch + $AUR_UPDATES AUR)" \
        -u normal
fi

# Save current count
echo "$TOTAL_UPDATES" > "$UPDATE_FILE_TMP"

# Output for polybar
if [ "$TOTAL_UPDATES" -gt 0 ]; then
    echo "$TOTAL_UPDATES"
else
    echo ""
fi