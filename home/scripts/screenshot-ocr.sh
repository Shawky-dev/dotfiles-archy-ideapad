#!/bin/bash
# Save as ~/bin/screenshot-ocr
TEMP_FILE="$HOME/Pictures/OCR/ocr_temp_$(date +%s).png"
OUTPUT_FILE="$HOME/Pictures/OCR/ocr_output_$(date +%s).txt"

# Take screenshot
flameshot gui -p "$TEMP_FILE"

# Check if screenshot was taken (user might cancel)
if [[ -f "$TEMP_FILE" ]] && [[ -s "$TEMP_FILE" ]]; then
    # Extract text and save to clipboard
    tesseract "$TEMP_FILE" - -l eng | xclip -selection clipboard
    
    # Also save to file for reference
    tesseract "$TEMP_FILE" "$OUTPUT_FILE" -l eng
    
    # Optional: Show extracted text in terminal
    echo "Text extracted to clipboard and saved to:"
    echo "$OUTPUT_FILE.txt"
    echo "--- Extracted Text Preview ---"
    head -n 5 "$OUTPUT_FILE.txt"
    echo "--- End Preview ---"
    
    notify-send "OCR Screenshot" "Text copied to clipboard!"
else
    notify-send "OCR Screenshot" "Screenshot cancelled"
    exit 1
fi

# Cleanup temporary image (optional)
# rm "$TEMP_FILE"