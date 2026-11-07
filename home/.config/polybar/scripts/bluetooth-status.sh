#!/bin/bash
# Polybar bluetooth: connected device names, "On" if none, "Off" if powered off.
# Requires: bluetoothctl (BlueZ 5.65+ for "devices Connected")

if ! bluetoothctl show | grep -q "Powered: yes"; then
    echo "Off"
    exit
fi

names=$(bluetoothctl devices Connected | cut -d ' ' -f 3- | paste -sd ',' | sed 's/,/, /g')
echo "${names:-On}"
