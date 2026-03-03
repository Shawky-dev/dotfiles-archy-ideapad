#!/bin/bash

set -euo pipefail

is_sleep_enabled() {
    local state
    state="$(systemctl is-enabled sleep.target 2>/dev/null || true)"
    [[ "$state" != "masked" ]]
}

print_status_icon() {
    if is_sleep_enabled; then
        # Hollow coffee mug when sleep is enabled.
        echo "󰛊"
    else
        # Filled coffee mug when sleep is disabled.
        echo "󰅶"
    fi
}

toggle_sleep() {
    if is_sleep_enabled; then
        systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
        notify-send "Sleep disabled 󰅶"
    else
        systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
        notify-send "Sleep enabled 󰛊"
    fi
}

case "${1:-toggle}" in
    status)
        print_status_icon
        ;;
    toggle)
        toggle_sleep
        ;;
    *)
        echo "Usage: $0 [status|toggle]"
        exit 1
        ;;
esac
