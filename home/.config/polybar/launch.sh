#!/bin/sh

# Kill existing polybar instances
killall -q polybar

# Wait until processes are shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

echo "---"  >> /tmp/polybar1.log

# Launch polybar for all monitors
# If you have multiple monitors, you might want to adjust this
if type "xrandr" > /dev/null; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload top >> /tmp/polybar1.log 2>&1 &
  done
else
  polybar --reload top >> /tmp/polybar1.log 2>&1 &
fi

echo "Polybar launched for i3..."