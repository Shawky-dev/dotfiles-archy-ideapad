#!/usr/bin/env bash
## Rofi : Todo list editor (the card is ~/scripts/utils/todo-card.py)
## Enter: check/uncheck · type + Enter: add · Shift+Del: delete · Alt+x: clear done

theme="$HOME/.config/rofi/themes/todo.rasi"
FILE="$HOME/notes/todo.md"
mkdir -p "$(dirname "$FILE")"
touch "$FILE"
# Open on the focused monitor, and bring the card there too
monitor=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .output')
"$HOME/scripts/utils/todo-card.py" --here &>/dev/null &

# Key legend under the list, two columns: highlighted key, then what it does
key() { printf '<span foreground="#d5c4a1"><b>%-*s</b></span>%-*s' "$1" "$2" "$3" "$4"; }
hints=$(
    key 11 "Enter"      12 "(un)check"; key 10 "Shift+Del" 0 "delete";     echo
    key 11 "Type+Enter" 12 "add task";  key 10 "Alt+x"     0 "clear done"; echo
    key 11 "Esc"        12 "close"
)

row=0
while true; do
    # Only task lines; open ones first. Keep their line numbers to edit the file.
    mapfile -t lines < <(grep -n '^- \[ \] ' "$FILE"; grep -n '^- \[[xX]\] ' "$FILE")

    choice=$(for l in "${lines[@]}"; do
        text=${l#*:}
        [[ $text == "- [ ] "* ]] && echo "☐  ${text:6}" || echo "☑  ${text:6}"
    done | rofi -dmenu -i -p "󰄵  Todo" -format 'i s' -selected-row "$row" ${monitor:+-m "$monitor"} \
        -mesg "$hints" \
        -kb-delete-entry "" -kb-custom-1 "Shift+Delete" -kb-custom-2 "Alt+x" \
        -theme "$theme")
    code=$?

    idx=${choice%% *}
    typed=${choice#* }
    lineno=""
    [[ $idx =~ ^[0-9]+$ ]] && (( idx < ${#lines[@]} )) && lineno=${lines[idx]%%:*} && row=$idx

    case $code in
        0)
            if [[ -n $lineno ]]; then
                if sed -n "${lineno}p" "$FILE" | grep -q '^- \[ \]'; then
                    sed -i "${lineno}s/^- \[ \]/- [x]/" "$FILE"
                else
                    sed -i "${lineno}s/^- \[[xX]\]/- [ ]/" "$FILE"
                fi
            elif [[ -n ${typed// } ]]; then
                printf -- '- [ ] %s\n' "$typed" >> "$FILE"
            fi ;;
        10) [[ -n $lineno ]] && sed -i "${lineno}d" "$FILE" ;;
        11) sed -i '/^- \[[xX]\] /d' "$FILE"; row=0 ;;
        *)  exit 0 ;;
    esac
done
