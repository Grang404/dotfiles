#!/bin/bash
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
THEME_FILE="$HOME/.config/rofi/themes/wallpaper.rasi"

cd "$WALLPAPER_DIR" || exit
selected=$(for file in *; do
	printf '%s\0icon\x1f%s\n' "$file" "$file"
done | rofi -dmenu -show-icons -theme "$THEME_FILE" -p "wallpaper")

[ -n "$selected" ] && swww img "$WALLPAPER_DIR/$selected" --resize=crop --transition-type=wipe --transition-angle=30 --transition-step=20 --transition-fps=60
