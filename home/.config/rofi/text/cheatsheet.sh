#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Cheatsheet Selector
#
## Available Styles
#
## style-1     style-2     style-3     style-4     style-5
## style-6     style-7     style-8     style-9     style-10
## style-11    style-12    style-13    style-14    style-15

dir="$HOME/.config/rofi/text/"
theme='style-3'

DIR="$HOME/.local/share/cheatsheets"

# Get list of files
selected=$(ls "$DIR" | rofi \
    -dmenu -i -p "Cheatsheets" \
    -theme ${dir}/${theme}.rasi)

[ -z "$selected" ] && exit 0

# Open in zathura
zathura "$DIR/$selected"
