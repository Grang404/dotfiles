#!/bin/bash

CONFIG_FILE="$HOME/.config/hypr/hyprland/keybinds.conf"
ROFI_THEME_DIR="$HOME/.config/rofi/themes"
ROFI_THEME="keybinds"

if ! command -v rofi &>/dev/null; then
	echo "Error: rofi is not installed"
	exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
	rofi -e "Hyprland config file not found at $CONFIG_FILE"
	exit 1
fi

extract_keybinds() {
	awk -F= '
		/^[[:space:]]*bind[[:space:]]*=/ {
			line = $2
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			n = split(line, parts, ",")
			for (i = 1; i <= n; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])

			if (n >= 3) {
				action = parts[3]
				for (i = 4; i <= n; i++) action = action "," parts[i]
				printf "%-20s → %s\n", parts[1] "+" parts[2], action
			} else {
				printf "%-20s → %s\n", "Unknown", line
			}
		}
	' "$CONFIG_FILE" | sort
}

main() {
	local keybinds
	keybinds=$(extract_keybinds)

	if [[ -z "$keybinds" ]]; then
		rofi -e "No keybinds found in $CONFIG_FILE"
		exit 1
	fi

	echo "$keybinds" | rofi -dmenu \
		-i \
		-p "Hyprland Keybinds" \
		-theme "${ROFI_THEME_DIR}/${ROFI_THEME}.rasi" \
		-no-custom
}

main
