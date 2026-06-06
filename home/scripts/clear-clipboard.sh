#!/usr/bin/env bash
# Clear copyq history
copyq remove $(seq 0 $(copyq count))
# Clear system clipboard
xclip -selection clipboard -i /dev/null
xclip -selection primary -i /dev/null
notify-send "Clipboard history cleared"
