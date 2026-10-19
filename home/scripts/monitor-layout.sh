#!/bin/sh
# Place external monitor(s) relative to the laptop screen, then restart polybar.
# Usage: monitor-layout.sh [left|right]   (no arg: reuse last choice, default left)
# rofi-args: left|right
# Output names are auto-detected, so it works with any HDMI/DP port.

state="${XDG_STATE_HOME:-$HOME/.local/state}/monitor-layout"

case "$1" in
  left|right) side="$1"; mkdir -p "$(dirname "$state")"; echo "$side" > "$state" ;;
  "")         side="$(cat "$state" 2>/dev/null)"; side="${side:-left}" ;;
  *)          echo "usage: $0 [left|right]" >&2; exit 1 ;;
esac

internal=$(xrandr --query | awk '/ connected/ && $1 ~ /^(eDP|LVDS|DSI)/ {print $1; exit}')
externals=$(xrandr --query | awk '/ connected/ && $1 !~ /^(eDP|LVDS|DSI)/ {print $1}')

if [ -n "$internal" ]; then
  anchor="$internal"
  for out in $externals; do
    xrandr --output "$internal" --auto --primary --output "$out" --auto --"$side"-of "$anchor"
    anchor="$out"  # chain multiple externals outward
  done
fi

# Bars must be relaunched to pick up the new geometry
"$HOME/.config/polybar/launch.sh" >/dev/null 2>&1
