#!/usr/bin/env bash

THEME_DIR="$HOME/.config/waybar/themes"
STYLE_FILE="$HOME/.config/waybar/style.css"

# Let the user pick a theme (basename without extension)
THEME=$(ls "$THEME_DIR"/*.css | xargs -n1 basename | sed 's/\.css$//' | fzf --prompt="Pick a Waybar theme: ")

# If nothing picked, just exit
[ -z "$THEME" ] && exit 0

# Write the import line to style.css
echo "@import \"themes/$THEME.css\";" > "$STYLE_FILE"

# Reload Waybar
pkill -USR2 waybar
