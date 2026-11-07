#!/bin/bash
# Polybar bluetooth icon: blue when a device is connected, normal when on, dim when off.
# Requires: bluetoothctl (BlueZ 5.65+ for "devices Connected")
icon=$''

if ! bluetoothctl show | grep -q "Powered: yes"; then
    echo "%{F#665c54}$icon%{F-}"
elif [ -n "$(bluetoothctl devices Connected)" ]; then
    echo "%{F#83a598}$icon%{F-}"
else
    echo "$icon"
fi
