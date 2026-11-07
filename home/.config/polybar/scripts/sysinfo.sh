#!/bin/bash
# Click on CPU/RAM/temp in polybar: one dunst notification with system details.
# Clicking again replaces it instead of stacking a new one.
# Kept to ~30 chars wide and 3 apps per list to fit dunst's 300px box.

idfile="${XDG_RUNTIME_DIR:-/tmp}/sysinfo-notify-id"

# App name of a pid: its program file (firefox's tabs are all "firefox"), else its command name
app() { basename "$(readlink "/proc/$1/exe" 2>/dev/null || cat "/proc/$1/comm" 2>/dev/null)"; }

# Current CPU from top's second sample (ps %cpu would be the lifetime average), summed per app
top_cpu=$(top -b -n 2 -d 0.5 | awk '/^ *PID/ { n++; next } n == 2 && $9 > 0 { print $1, $9 }' |
    while read -r pid cpu; do echo "$(app "$pid") $cpu"; done |
    awk '{ s[$1] += $2 } END { for (a in s) printf "%-14.14s %6.1f%%\n", a, s[a] }' | sort -k2 -rn | head -3)
top_mem=$(ps -eo pid=,rss= | while read -r pid rss; do echo "$(app "$pid") $rss"; done |
    awk '$1 != "" { s[$1] += $2 } END { for (a in s) printf "%-14.14s %6.1fG\n", a, s[a] / 1048576 }' |
    sort -k2 -rn | head -3)

read -r load1 load5 load15 _ < /proc/loadavg
ghz=$(awk '/^cpu MHz/ { s += $4; n++ } END { if (n) printf "%.1f GHz", s / n / 1000 }' /proc/cpuinfo)
temp=""
for h in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$h/name" 2>/dev/null)" = k10temp ] && temp=" · $(( $(cat "$h/temp1_input") / 1000 ))°C" && break
done
ram=$(free -h --si | awk '/^Mem:/ { print $3 " / " $2 }')
swap=$(free -h --si | awk '/^Swap:/ { print $3 " / " $2 }')
up=$(awk '{ h = int($1 / 3600); m = int($1 % 3600 / 60); printf (h ? h "h " : "") m "m" }' /proc/uptime)

body="<span font='monospace'>Load  $load1 $load5 $load15
CPU   $ghz$temp
RAM   $ram
Swap  $swap
Up    $up

<b>Top CPU</b>
$top_cpu
<b>Top memory</b>
$top_mem</span>"

old=$(cat "$idfile" 2>/dev/null)
notify-send -u low -a Sysinfo -p ${old:+-r "$old"} "System" "$body" > "$idfile"
