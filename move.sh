#!/bin/bash

set -eE

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTS_DIR="$SCRIPT_DIR/dots"
readonly CONFIG_DIR="$HOME/.config"

print_msg() {
	echo -e "${BOLD}${BLUE}[*]${NC} $1"
}

print_success() {
	echo -e "${BOLD}${GREEN}[+]${NC} $1"
}

print_error() {
	echo -e "${BOLD}${RED}[!]${NC} $1"
}

print_warning() {
	echo -e "${BOLD}${YELLOW}[!]${NC} $1"
}

detect_profile() {
	if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
		echo "laptop"
	else
		echo "desktop"
	fi
}

update_dotfiles() {
	local profile=$(detect_profile)
	print_msg "Detected profile: $profile"

	if [[ ! -d "$DOTS_DIR" ]]; then
		print_error "dots directory not found: $DOTS_DIR"
		exit 1
	fi

	local shared_dirs=("btop" "eza" "fastfetch" "ghostty" "gtk-2.0" "gtk-3.0" "gtk-4.0" "nvim" "rofi" "xdg" "zsh" "waybar")

	for dir in "${shared_dirs[@]}"; do
		if [[ -d "$DOTS_DIR/$dir" ]]; then
			print_msg "Updating $dir..."

			if [[ "$dir" == "waybar" ]]; then
				rsync -a --delete \
					--exclude="$profile.jsonc" \
					"$DOTS_DIR/$dir/" "$CONFIG_DIR/$dir/"

				if [[ -f "$DOTS_DIR/waybar/$profile.jsonc" ]]; then
					cp "$DOTS_DIR/waybar/$profile.jsonc" "$CONFIG_DIR/waybar/config.jsonc"
					print_msg "Updated waybar config.jsonc from $profile.jsonc"
				fi
			else
				rsync -a --delete "$DOTS_DIR/$dir/" "$CONFIG_DIR/$dir/"
			fi

			print_success "Updated $dir"
		fi
	done

	if [[ -d "$DOTS_DIR/hypr" ]]; then
		print_msg "Updating hypr..."

		rsync -a --delete \
			--exclude="laptop/" \
			--exclude="desktop/" \
			"$DOTS_DIR/hypr/" "$CONFIG_DIR/hypr/"

		if [[ -d "$DOTS_DIR/hypr/$profile" ]]; then
			rsync -a "$DOTS_DIR/hypr/$profile/" "$CONFIG_DIR/hypr/"
			print_msg "Updated hypr from $profile profile"
		fi

		if [[ -f "$CONFIG_DIR/hypr/hyprland.conf" ]]; then
			sed -i "1i\$DEVICE = $profile" "$CONFIG_DIR/hypr/hyprland.conf"
			print_msg "Added \$DEVICE = $profile to hyprland.conf"
		fi

		print_success "Updated hypr"
	fi

	for dotfile in "zshrc" "p10k.zsh" "zprofile"; do
		if [[ -f "$DOTS_DIR/$dotfile" ]]; then
			print_msg "Updating $dotfile..."
			cp "$DOTS_DIR/$dotfile" "$HOME/.$dotfile"
			print_success "Updated $dotfile"
		fi
	done

	local firefox_profile
	firefox_profile=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -n1)
	if [[ -n "$firefox_profile" && -f "$DOTS_DIR/firefox/user.js" ]]; then
		print_msg "Updating Firefox user.js..."
		cp "$DOTS_DIR/firefox/user.js" "$firefox_profile/user.js"
		print_success "Updated Firefox user.js"
	fi

	print_success "Dotfiles updated successfully!"
}

main() {
	print_msg "Updating dotfiles from repository..."
	update_dotfiles
}

main
