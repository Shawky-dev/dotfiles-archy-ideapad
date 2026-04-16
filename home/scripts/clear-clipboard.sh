#!/usr/bin/env bash

# Kill greenclip daemon
pkill greenclip

# Clear clipboard
xclip -selection clipboard -i /dev/null
xclip -selection primary -i /dev/null

# Clear greenclip history file
rm -f ~/.cache/greenclip.history

# Restart greenclip
sleep 0.5
greenclip daemon > /dev/null 2>&1 &

notify-send "Clipboard history cleared"
