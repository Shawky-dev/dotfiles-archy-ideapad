#!/usr/bin/env bash

# Directories
SOURCE_DIR="$HOME/Videos/OBS"
TARGET_DIR="$HOME/Videos/davinci-videos"

# Ensure output folder exists
mkdir -p "$TARGET_DIR"

# Let the user fzf a file from SOURCE_DIR
selected=$(find "$SOURCE_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" \) | fzf --prompt="Select video to convert: ")

# If no file selected, exit
if [ -z "$selected" ]; then
    echo "No file selected. Exiting."
    exit 1
fi

# Basename and output name
base="$(basename "$selected")"
name="${base%.*}"
output="$TARGET_DIR/${name}_dnxhr.mov"

# FFmpeg DNxHR conversion (Resolve-friendly)
echo "Converting: $selected → $output"
ffmpeg -hide_banner -loglevel info \
    -i "$selected" \
    -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
    -c:a pcm_s16le \
    "$output"

# Check for success
if [ $? -eq 0 ]; then
    echo "Finished conversion. Output saved to: $output"
else
    echo "Conversion failed!"
    exit 1
fi
