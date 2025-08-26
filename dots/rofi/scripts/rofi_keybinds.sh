#!/bin/bash

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
	echo "Error: Hyprland config file not found at $CONFIG_FILE"
	rofi -e "Hyprland config file not found at $CONFIG_FILE"
	exit 1
fi

if ! command -v rofi &>/dev/null; then
	echo "Error: rofi is not installed"
	exit 1
fi

format_keybind() {
	local line="$1"

	# remove 'bind=' prefix and trim whitespace
	line=$(echo "$line" | sed 's/^[[:space:]]*bind[[:space:]]*=[[:space:]]*//')

	# split by comma and format
	IFS=',' read -ra PARTS <<<"$line"

	if [[ ${#PARTS[@]} -ge 3 ]]; then
		local modifiers="${PARTS[0]}"
		local key="${PARTS[1]}"
		local action="${PARTS[2]}"

		modifiers=$(echo "$modifiers" | xargs)
		key=$(echo "$key" | xargs)
		action=$(echo "$action" | xargs)

		if [[ ${#PARTS[@]} -gt 3 ]]; then
			for ((i = 3; i < ${#PARTS[@]}; i++)); do
				action="$action,${PARTS[i]}"
			done
		fi

		printf "%-20s → %s\n" "$modifiers+$key" "$action"
	else
		printf "%-20s → %s\n" "Unknown" "$line"
	fi
}

extract_keybinds() {
	local temp_file=$(mktemp)

	grep -E '^[[:space:]]*bind[[:space:]]*=' "$CONFIG_FILE" | while IFS= read -r line; do
		format_keybind "$line"
	done | sort >"$temp_file"

	if [[ ! -s "$temp_file" ]]; then
		echo "No keybinds found in $CONFIG_FILE"
		rm "$temp_file"
		return 1
	fi

	cat "$temp_file"
	rm "$temp_file"
}

main() {
	local keybinds
	if ! keybinds=$(extract_keybinds); then
		rofi -e "No keybinds found in $CONFIG_FILE"
		exit 1
	fi

	dir="$HOME/.config/rofi"
	theme='groobofi'

	echo "$keybinds" | rofi -dmenu \
		-i \
		-p "Hyprland Keybinds" \
		-theme "${dir}/${theme}.rasi" \
		-no-custom
}

main
