#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_msg() {
	echo -e "${BOLD}${BLUE}[*]${NC} $1"
}
print_success() {
	echo -e "${BOLD}${GREEN}[+]${NC} $1"
}
print_error() {
	echo -e "${BOLD}${RED}[!]${NC} $1"
}

if [ "$EUID" -ne 0 ]; then
	print_error "Please run as sudo."
	exit 1
fi

detect_battery() {
	[[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]
}

if detect_battery; then
	PROFILE=laptop
else
	PROFILE=desktop
fi

print_msg "Updating system..."
pacman -Syu --noconfirm

print_msg "Installing packages..."

core_packages=(
	base base-devel git curl wget hyprland hyprlock hyprshot
	hyprpicker hyprpolkitagent waybar wireplumber wl-clipboard
	wtype xdg-desktop-portal-hyprland xdg-utils dhcpcd
)

laptop_packages=(
	tlp tlp-rdw bluez bluez-utils impala powertop iwd
)

application_packages=(
	discord steam firefox ghostty neovim obsidian
	mpv pavucontrol imv yazi
)

font_packages=(
	ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji gnu-free-fonts
)

utility_packages=(
	zsh swww rofi-wayland ffmpeg jq poppler fd fzf zoxide imagemagick
	btop fastfetch go less man-db man-pages npm
	ntfs-3g p7zip ripgrep rsync luarocks tree unzip
	cronie eza bind
)

groups=("core" "application" "font" "utility")
[[ "$PROFILE" == "laptop" ]] && groups+=("laptop")

for group_name in "${groups[@]}"; do
	local -n current_group="${group_name}_packages"
	print_msg "Installing $group_name packages..."
	pacman -S --needed --noconfirm "${current_group[@]}"
	print_success "Successfully installed $group_name packages"
done

print_success "Installation completed!"
