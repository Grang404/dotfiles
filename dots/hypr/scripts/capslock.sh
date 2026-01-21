#!/bin/bash
caps_on=false

for led in /sys/class/leds/input*::capslock/brightness; do
	if [ -f "$led" ]; then
		brightness=$(cat "$led" 2>/dev/null)
		if [ "$brightness" = "1" ]; then
			caps_on=true
			break
		fi
	fi
done

if [ "$caps_on" = true ]; then
	echo "󰌎"
else
	echo ""
fi
