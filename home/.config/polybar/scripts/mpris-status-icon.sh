#!/bin/bash
#
# mpris-status-icon.sh -- shows play/pause icon and toggles prev/next visibility
#
# Requires: playerctl

to_icon() {
    while IFS= read -r event; do
        if ! playerctl metadata >/dev/null 2>&1; then
            echo ""
            polybar-msg action mpris-prev hook 0 >/dev/null 2>&1
            polybar-msg action mpris-next hook 0 >/dev/null 2>&1
        else
            polybar-msg action mpris-prev hook 1 >/dev/null 2>&1
            polybar-msg action mpris-next hook 1 >/dev/null 2>&1
            case "$event" in
                Playing)
                    echo ""
                    ;;
                Stopped|Paused)
                    echo ""
                    ;;
                *)
                    echo "$event"
                    ;;
            esac
        fi
    done
}

playerctl status --follow | to_icon
