#!/bin/sh
# Start one bar per active monitor. Run again to restart them.

killall -q polybar
# A bar that misses the signal (e.g. mid-reload) gets force-killed after ~3s
tries=0
while pgrep -u "$(id -u)" -x polybar >/dev/null; do
  tries=$((tries + 1))
  [ "$tries" -ge 15 ] && killall -q -9 polybar
  sleep 0.2
done

echo "---" >> /tmp/polybar1.log

# CPU temperature sensor (AMD k10temp). hwmon numbers can change between
# boots, so look it up by name; config.ini falls back to thermal zone 0.
for h in /sys/class/hwmon/hwmon*; do
  [ "$(cat "$h/name" 2>/dev/null)" = k10temp ] && CPU_TEMP="$h/temp1_input" && break
done
export CPU_TEMP

# The primary monitor gets the bar with the tray (only one bar can own it).
polybar --list-monitors | while IFS= read -r line; do
  monitor=${line%%:*}
  case $line in
    *"(primary)"*) bar=top-primary ;;
    *) bar=top ;;
  esac
  MONITOR=$monitor polybar --reload "$bar" >> /tmp/polybar1.log 2>&1 &
done

echo "Polybar launched for i3..."
