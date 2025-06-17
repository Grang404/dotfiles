#!/bin/bash

# Set DP-2 to 1920x1080 at 239.76Hz
xrandr --output DP-2 --mode 1920x1080 --rate 239.76 --primary

# Set DP-0 to 1920x1080 at 143.99Hz and place it to the right of DP-2
xrandr --output DP-0 --mode 1920x1080 --rate 143.99 --right-of DP-2
