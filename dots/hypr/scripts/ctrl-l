#!/bin/bash
active_class=$(hyprctl activewindow -j | jq -r '.class')
if [[ "$active_class" == "firefox" ]]; then
	wtype -M ctrl -k l
else
	hyprctl dispatch movefocus d
fi
