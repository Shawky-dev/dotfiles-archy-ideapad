#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Cheatsheet Selector

theme="$HOME/.config/rofi/themes/menu.rasi"

DIR="$HOME/Documents/cheatsheets"

# Get list of files
selected=$(ls "$DIR" | rofi \
    -dmenu -i -p "Cheatsheets" \
    -theme "$theme")

[ -z "$selected" ] && exit 0

# Open in zathura
zathura "$DIR/$selected"
