#!/bin/bash

today=$(date +%-d)

cal_output=$(cal | perl -pe "
    # Skip the month/year header line and the weekday-abbreviation line
    if (\$. > 2) {
        s/\b${today}\b/<b><span color='#f00'>${today}<\/span><\/b>/g;
    }
")

notify-send -u low -i "date" "Calendar" "<span font='monospace'>$cal_output</span>"