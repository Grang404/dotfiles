#!/bin/bash

# Configuration
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
THEME_FILE="$HOME/.config/rofi/themes/wallpaper.rasi"

# Check if wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
	echo "Error: Wallpaper directory '$WALLPAPER_DIR' does not exist"
	exit 1
fi

# Launch rofi with filebrowser and swww integration
rofi -theme "$THEME_FILE" \
	-show filebrowser \
	-filebrowser-directory "$WALLPAPER_DIR" \
	-filebrowser-command "swww img --resize=crop --transition-type=wipe --transition-angle=30 --transition-step=20 --transition-fps=60" \
	-filebrowser-sorting-method name
