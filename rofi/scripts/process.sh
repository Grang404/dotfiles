#!/bin/bash

dir="$HOME/.config/rofi"
theme='groobofi'

format_processes() {
    ps -eo pid,pcpu,comm --no-headers | awk '
    !/\[.*\]/ {
        pid = $1
        cpu = $2
        process_name = $3
        split(process_name, path_parts, "/")
        process_name = path_parts[length(path_parts)]
        printf "%s|%s|%s\n", process_name, pid, cpu
    }' | sort -t'|' -k3 -nr | awk -F'|' '{ printf "%s (%s)\n", $1, $2 }'
}

process_list=$(format_processes)

selected=$(echo "$process_list" | rofi -dmenu -i -p "Select process to kill (sorted by CPU usage):" -format "s" -no-custom -theme "${dir}/${theme}.rasi")

if [ -z "$selected" ]; then
    exit 0
fi

pid=$(echo "$selected" | sed -E "s/.*\(([0-9]+)\).*/\1/")
process_name=$(echo "$selected" | sed -E "s/ \([0-9]+\)//")

if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
    rofi -e "Invalid selection" -theme "${dir}/${theme}.rasi"
    exit 1
fi

details="Process: $process_name
PID: $pid

Do you want to kill this process?"

confirm=$(echo -e "Kill (TERM)\nForce Kill (KILL)\nCancel" | rofi -dmenu -p "Action for process $pid:" -mesg "$details" -theme "${dir}/${theme}.rasi")

case "$confirm" in
"Kill (TERM)")
    if kill "$pid" 2>/dev/null; then
        notify-send "Process Killed" "Successfully terminated process $pid" 2>/dev/null || echo "Process $pid terminated successfully"
    else
        if sudo kill "$pid" 2>/dev/null; then
            notify-send "Process Killed" "Successfully terminated process $pid (with sudo)" 2>/dev/null || echo "Process $pid terminated successfully (with sudo)"
        else
            notify-send "Kill Failed" "Failed to terminate process $pid" 2>/dev/null || echo "Failed to terminate process $pid"
        fi
    fi
    ;;
"Force Kill (KILL)")
    if kill -9 "$pid" 2>/dev/null; then
        notify-send "Process Force Killed" "Force killed process $pid" 2>/dev/null || echo "Process $pid force killed successfully"
    else
        if sudo kill -9 "$pid" 2>/dev/null; then
            notify-send "Process Force Killed" "Force killed process $pid (with sudo)" 2>/dev/null || echo "Process $pid force killed successfully (with sudo)"
        else
            notify-send "Kill Failed" "Failed to force kill process $pid" 2>/dev/null || echo "Failed to force kill process $pid"
        fi
    fi
    ;;
"Cancel" | "")
    exit 0
    ;;
esac
