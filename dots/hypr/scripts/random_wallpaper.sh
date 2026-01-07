WALLPAPER_DIR="$HOME/Pictures/wallpapers"

file=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

swww img --resize=crop --transition-type=wipe --transition-angle=30 --transition-step=20 --transition-fps=60 "$file"
