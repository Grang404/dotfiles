#!/bin/bash

case $(tlp-stat -s | grep "Power profile" | awk -F'= ' '{print $2}' | cut -d'/' -f1) in
    performance) echo '{"text":"󱐋","tooltip":"TLP Profile: performance"}' ;;
    balanced) echo '{"text":"󰾅","tooltip":"TLP Profile: balanced"}' ;;
    low-power) echo '{"text":"󰾆","tooltip":"TLP Profile: low-power"}' ;;
    *) echo '{"text":"󰂎 unknown","tooltip":"TLP status unavailable"}' ;;
esac
