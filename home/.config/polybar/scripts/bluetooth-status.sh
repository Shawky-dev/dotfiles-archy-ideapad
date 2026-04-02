#!/bin/bash
#
# Requires: bluetoothctl

power_on() {
    bluetoothctl show | grep -q "Powered: yes"
}

device_connected() {
    bluetoothctl info "$1" | grep -q "Connected: yes"
}

if power_on; then
    mapfile -t paired_devices < <(bluetoothctl paired-devices | grep Device | cut -d ' ' -f 2)
    counter=0
    for device in "${paired_devices[@]}"; do
        if device_connected "$device"; then
            device_alias=$(bluetoothctl info "$device" | grep "Alias" | cut -d ' ' -f 2-)
            if [ $counter -gt 0 ]; then
                printf ", %s" "$device_alias"
            else
                printf " %s" "$device_alias"
            fi
            ((counter++))
        fi
    done
    if [ $counter -eq 0 ]; then
        echo "On"
    else
        echo ""
    fi
else
    echo "Off"
fi
