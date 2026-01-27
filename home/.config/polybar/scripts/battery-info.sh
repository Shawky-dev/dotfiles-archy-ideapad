#!/bin/bash

# Get battery details from acpi
# You may need to install 'acpi' if you don't have it
BAT_INFO=$(acpi -b | sed 's/Battery 0: //')

# Get power profile (Performance, Balanced, Power-saver)
# Works if power-profiles-daemon is installed
POWER_MODE=$(powerprofilesctl get 2>/dev/null || echo "N/A")

# Send the notification to Dunst
notify-send -u low -i "battery-good" \
    "Battery Details" \
    "<b>Status:</b> $BAT_INFO\n<b>Power Mode:</b> $POWER_MODE"