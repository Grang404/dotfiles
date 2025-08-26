#!/bin/bash

# TODO: Add input for resolution and monitors
# TODO: Ensure the permissions are not broad

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Global variables to track installation state
INSTALLATION_SUCCESSFUL=false
INSTALLATION_STARTED=false
BACKUPS_CREATED=false
PACKAGES_INSTALLED=false
SERVICES_ENABLED=false
DOTFILES_MOVED=false

# Arrays to track what we've done for selective rollback
INSTALLED_PACKAGES=()
ENABLED_SERVICES=()
BACKUP_LOCATIONS=()

# Set error handling
set -eE # Exit on error and inherit ERR trap in functions
trap 'handle_error $? $LINENO' ERR
trap 'final_cleanup' EXIT
trap 'handle_interrupt' INT TERM

LOG_FILE="$SCRIPT_DIR/install_script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

print_msg() {
	echo -e "${BOLD}${BLUE}[*]${NC} $1"
}

print_success() {
	echo -e "${BOLD}${GREEN}[+]${NC} $1"
}

print_error() {
	echo -e "${BOLD}${RED}[!]${NC} $1"
}

handle_error() {
	local exit_code=$1
	local line_number=$2

	print_error "Installation failed at line $line_number with exit code $exit_code"

	if [[ "$INSTALLATION_STARTED" == true ]]; then
		print_error "Rolling back changes..."
		rollback_installation
	fi

	exit "$exit_code"
}

handle_interrupt() {
	print_error "Installation interrupted by user"

	if [[ "$INSTALLATION_STARTED" == true ]]; then
		print_error "Rolling back changes..."
		rollback_installation
	fi

	exit 130
}

final_cleanup() {
	cleanup_temp_files
	cleanup_package_manager

	if [[ "$INSTALLATION_SUCCESSFUL" == true ]]; then
		print_success "Installation completed successfully!"
		print_msg "System cleanup completed"
		print_msg "Please reboot your system"
	fi
}

cleanup_temp_files() {
	print_msg "Cleaning up temporary files..."

	if [ -d "/tmp/paru" ]; then
		rm -rf /tmp/paru
	fi

	if [ -d "/tmp/install_script_temp" ]; then
		rm -rf /tmp/install_script_temp
	fi
}

cleanup_package_manager() {
	print_msg "Cleaning package manager state..."

	pacman -Sc --noconfirm >/dev/null 2>&1 || true

	if pgrep -x "pacman" >/dev/null; then
		print_msg "Killing hanging pacman processes..."
		pkill -x pacman || true
		sleep 2
	fi

	if [ -f "/var/lib/pacman/db.lck" ]; then
		print_msg "Removing pacman lock file..."
		rm -f /var/lib/pacman/db.lck
	fi
}

create_backup() {
	local source_path="$1"
	local backup_suffix="$2"

	if [ -e "$source_path" ]; then
		local backup_path="${source_path}${backup_suffix}"
		print_msg "Creating backup: $backup_path"

		if cp -r "$source_path" "$backup_path"; then
			BACKUP_LOCATIONS+=("$source_path:$backup_path")
			return 0
		else
			print_error "Failed to create backup of $source_path"
			return 1
		fi
	fi
	return 0
}

restore_backups() {
	print_msg "Restoring backups..."

	for backup_entry in "${BACKUP_LOCATIONS[@]}"; do
		IFS=':' read -r original backup <<<"$backup_entry"

		if [ -e "$backup" ]; then
			print_msg "Restoring $original from backup..."
			rm -rf "$original" 2>/dev/null || true
			mv "$backup" "$original" || {
				print_error "Failed to restore $original"
			}
			chown -R "$SUDO_USER:$SUDO_USER" "$original" 2>/dev/null || true
		fi
	done
}

rollback_services() {
	if [[ "$SERVICES_ENABLED" == true ]]; then
		print_msg "Disabling services..."

		for service in "${ENABLED_SERVICES[@]}"; do
			print_msg "Disabling $service..."
			if [[ "$service" == *"--user"* ]]; then
				# User service - extract actual service name
				local service_name=${service#*--user }
				sudo -u "$SUDO_USER" systemctl --user disable --now "$service_name" 2>/dev/null || true
			else
				# System service
				systemctl disable --now "$service" 2>/dev/null || true
			fi
		done
	fi
}

rollback_packages() {
	if [[ "$PACKAGES_INSTALLED" == true ]] && [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]]; then
		print_msg "Removing installed packages..."

		# Remove packages in reverse order
		for ((i = ${#INSTALLED_PACKAGES[@]} - 1; i >= 0; i--)); do
			local package="${INSTALLED_PACKAGES[$i]}"
			print_msg "Removing $package..."
			pacman -Rns --noconfirm "$package" 2>/dev/null || true
		done
	fi
}

rollback_installation() {
	print_error "Rolling back installation due to failure..."

	if [[ "$DOTFILES_MOVED" == true ]]; then
		restore_backups
	fi

	rollback_services

	# Note: We generally DON'T rollback packages unless specifically requested
	# because partial package removal can break the system worse than leaving them
	print_msg "Packages left installed (removing them could cause issues)"
	print_msg "If you want to remove packages, run: pacman -Rns [package_names]"

	cleanup_temp_files
	cleanup_package_manager

	print_error "Rollback completed"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
	print_error "Please run as sudo."
	false
fi

# Check if SUDO_USER is set
if [ -z "$SUDO_USER" ]; then
	print_error "SUDO_USER is not set. Run the script using 'sudo -E'."
	exit 1
fi

show_banner() {
	clear

	# Print top border
	echo -e "$CYAN"
	printf '%.0s═' {1..80}
	echo -e "$NC"
	echo

	# Print ASCII art
	echo -e "$RED"
	cat <<'EOF'
                                                                
 @@@@@@@@  @@@@@@@    @@@@@@    @@@@@@   @@@@@@@                
@@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@               
!@@        @@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@               
!@!        !@!  @!@  !@!  @!@  !@!  @!@  !@   @!@               
!@! @!@!@  @!@!!@!   @!@  !@!  @!@  !@!  @!@!@!@                
!!! !!@!!  !!@!@!    !@!  !!!  !@!  !!!  !!!@!!!!               
:!!   !!:  !!: :!!   !!:  !!!  !!:  !!!  !!:  !!!               
:!:   !::  :!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!               
 ::: ::::  ::   :::  ::::: ::  ::::: ::   :: ::::               
 :: :: :    :   : :   : :  :    : :  :   :: : ::                
                                                                
                                                                
@@@  @@@  @@@   @@@@@@   @@@@@@@   @@@@@@   @@@       @@@       
@@@  @@@@ @@@  @@@@@@@   @@@@@@@  @@@@@@@@  @@@       @@@       
@@!  @@!@!@@@  !@@         @@!    @@!  @@@  @@!       @@!       
!@!  !@!!@!@!  !@!         !@!    !@!  @!@  !@!       !@!       
!!@  @!@ !!@!  !!@@!!      @!!    @!@!@!@!  @!!       @!!       
!!!  !@!  !!!   !!@!!!     !!!    !!!@!!!!  !!!       !!!       
!!:  !!:  !!!       !:!    !!:    !!:  !!!  !!:       !!:       
:!:  :!:  !:!      !:!     :!:    :!:  !:!   :!:       :!:      
 ::   ::   ::  :::: ::      ::    ::   :::   :: ::::   :: ::::  
:    ::    :   :: : :       :      :   : :  : :: : :  : :: : :  
EOF
	echo -e "$NC"
	echo

	# Print bottom border
	echo -e "$CYAN"
	printf '%.0s═' {1..80}
	echo -e "$NC"
	echo
	echo
}

USER_HOME=$(eval echo ~"$SUDO_USER")

update_system() {
	print_msg "Updating system..."
	pacman -Syu --noconfirm || {
		print_error "Failed to update system."
		return 1
	}
}

enable_multilib() {
	print_msg "Enabling multilib repository..."

	if grep -q "^\[multilib\]" /etc/pacman.conf; then
		print_msg "Multilib already enabled, skipping..."
		return 0
	fi

	sed -i '/^\#\[multilib\]/,/^\#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf

	pacman -Sy --noconfirm || {
		print_error "Failed to update package database after enabling multilib"
		return 1
	}

	print_success "Multilib enabled successfully"
}

safe_install_packages() {
	print_msg "Installing base packages..."
	INSTALLATION_STARTED=true

	# Define package groups for better error handling
	local core_packages=(
		base base-devel git curl wget
	)

	local system_packages=(
		alsa-utils inetutils reflector aria2 dmidecode
		dnsmasq dosfstools dysk evtest exfat-utils
	)

	local desktop_packages=(
		hyprland hyprlock hyprpaper hyprshot hyprpicker
		hyprpolkitagent waybar wireplumber wl-clipboard
		wtype xdg-desktop-portal-hyprland xdg-utils
	)

	local application_packages=(
		discord steam firefox kitty neovim obsidian
		vlc pavucontrol gparted
	)

	local font_packages=(
		ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji gnu-free-fonts
	)

	local utility_packages=(
		zsh ly gamemode lib32-gamemode swww imv rofi-wayland
		yazi ffmpeg jq poppler fd fzf zoxide imagemagick
		btop fastfetch go less man-db man-pages npm
		ntfs-3g p7zip ripgrep rsync luarocks tree unzip
		cronie lm_sensors
	)

	# Install each group with individual error handling
	for group_name in "core" "system" "desktop" "application" "font" "utility"; do
		local -n current_group="${group_name}_packages"

		print_msg "Installing $group_name packages..."

		if pacman -S --needed --noconfirm "${current_group[@]}"; then
			INSTALLED_PACKAGES+=("${current_group[@]}")
			print_success "Successfully installed $group_name packages"
		else
			print_error "Failed to install $group_name packages"
			return 1
		fi
	done

	PACKAGES_INSTALLED=true
}

install_driver() {
	print_msg "Installing $1..."
	if pacman -S --noconfirm --needed "$1"; then
		INSTALLED_PACKAGES+=("$1")
		print_success "Successfully installed $1"
	else
		print_error "Failed to install $1"
		return 1
	fi
}

install_vm_driver() {
	if grep -q 'QEMU' /sys/class/dmi/id/product_name 2>/dev/null; then
		print_msg "QEMU VM detected, installing virtio video driver..."
		install_driver xf86-video-virtio || return 1
		return 0
	fi
	return 1
}

detect_gpu() {
	lspci | grep -Ei 'vga|3d' | head -n1 | grep -oEi 'nvidia|amd|advanced micro devices|intel' | tr '[:upper:]' '[:lower:]'
}

map_gpu_to_choice() {
	case "$1" in
	nvidia) echo 1 ;;
	amd | advanced\ micro\ devices) echo 2 ;;
	intel) echo 3 ;;
	*) echo "" ;;
	esac
}

manual_choice() {
	echo "Please select your GPU driver to install:"
	echo "1) nvidia"
	echo "2) amd"
	echo "3) intel"
	read -rp "Enter choice [1-3]: " choice
	echo "$choice"
}

choose_gpu_driver() {
	local detected_gpu detected_choice choice confirm

	detected_gpu=$(detect_gpu)
	detected_choice=$(map_gpu_to_choice "$detected_gpu")

	if [[ -n "$detected_choice" ]]; then
		print_msg "Detected GPU vendor: $detected_gpu"
		read -rp "Use detected GPU driver? [Y/n]: " confirm
		if [[ "$confirm" =~ ^[Nn]$ ]]; then
			choice=$(manual_choice)
		else
			choice=$detected_choice
		fi
	else
		print_msg "Could not auto-detect GPU."
		choice=$(manual_choice)
	fi

	echo "$choice"
}

install_gpu_driver() {
	if install_vm_driver; then
		return 0
	fi

	local choice=$1

	case $choice in
	1)
		install_driver linux-headers || return 1
		install_driver dkms || return 1
		install_driver nvidia-dkms || return 1
		install_driver nvidia-settings || return 1
		install_driver lib32-nvidia-utils || return 1
		;;
	2)
		install_driver linux-headers || return 1
		install_driver xf86-video-amdgpu || return 1
		install_driver lib32-mesa || return 1
		install_driver lib32-vulkan-radeon || return 1
		;;
	3)
		install_driver linux-headers || return 1
		install_driver xf86-video-intel || return 1
		install_driver lib32-mesa || return 1
		install_driver lib32-vulkan-intel || return 1
		;;
	*)
		print_error "Invalid GPU choice: $choice"
		return 1
		;;
	esac
}

install_paru() {
	print_msg "Installing paru..."
	if ! command -v paru &>/dev/null; then
		cd /tmp || return 1
		git clone https://aur.archlinux.org/paru.git || {
			print_error "Failed to clone paru"
			return 1
		}
		chown -R "$SUDO_USER:$SUDO_USER" paru
		cd paru || return 1
		sudo -u "$SUDO_USER" makepkg -si --noconfirm || {
			print_error "Failed to install paru"
			return 1
		}
		print_success "Successfully installed paru!"
		cd "$SCRIPT_DIR" || return 1
	else
		print_msg "paru is already installed"
	fi
}

install_paru_packages() {
	print_msg "Installing paru packages..."
	local paru_packages=(
		qdirstat
		nvibrant-bin
		noisetorch
	)

	for package in "${paru_packages[@]}"; do
		print_msg "Installing $package..."
		if sudo -u "$SUDO_USER" paru -S --needed --noconfirm "$package"; then
			print_success "Successfully installed $package"
		else
			print_error "Failed to install $package"
			return 1
		fi
	done

	print_success "Successfully installed all paru packages!"
}

safe_enable_services() {
	print_msg "Enabling system services..."

	local system_services=(
		"NetworkManager"
		"ly.service"
		"cronie.service"
		"lm_sensors.service"
		"bluetooth.service"
		"fstrim.timer"
	)

	local user_services=(
		"pipewire.service"
		"pipewire-pulse.service"
		"wireplumber.service"
	)

	# Enable system services one by one
	for service in "${system_services[@]}"; do
		print_msg "Enabling $service..."
		if systemctl enable --now "$service"; then
			ENABLED_SERVICES+=("$service")
		else
			print_error "Failed to enable $service"
			return 1
		fi
	done

	# Enable user services
	for service in "${user_services[@]}"; do
		print_msg "Enabling user $service..."
		if sudo -u "$SUDO_USER" systemctl --user enable --now "$service"; then
			ENABLED_SERVICES+=("--user $service")
		else
			print_error "Failed to enable user $service"
			return 1
		fi
	done

	SERVICES_ENABLED=true
	print_success "Services enabled successfully"
}

install_zsh_plugins() {
	print_msg "Installing ZSH plugins and theme..."

	ZSH_CONFIG_DIR="$USER_HOME/.config/zsh"
	PLUGINS_DIR="$ZSH_CONFIG_DIR/plugins"
	THEMES_DIR="$ZSH_CONFIG_DIR/themes"

	mkdir -p "$PLUGINS_DIR" "$THEMES_DIR"

	if [ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
		git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DIR/zsh-autosuggestions" || {
			print_error "Failed to install zsh-autosuggestions"
			return 1
		}
		print_success "Installed zsh-autosuggestions"
	else
		print_msg "zsh-autosuggestions already exists, skipping..."
	fi

	# Install zsh-syntax-highlighting
	if [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
		git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGINS_DIR/zsh-syntax-highlighting" || {
			print_error "Failed to install zsh-syntax-highlighting"
			return 1
		}
		print_success "Installed zsh-syntax-highlighting"
	else
		print_msg "zsh-syntax-highlighting already exists, skipping..."
	fi

	# Install powerlevel10k theme
	if [ ! -d "$THEMES_DIR/powerlevel10k" ]; then
		git clone --depth=1 https://github.com/romkatv/powerlevel10k "$THEMES_DIR/powerlevel10k" || {
			print_error "Failed to install powerlevel10k"
			return 1
		}
		print_success "Installed powerlevel10k theme"
	else
		print_msg "powerlevel10k already exists, skipping..."
	fi

	# Set proper ownership
	chown -R "$SUDO_USER:$SUDO_USER" "$ZSH_CONFIG_DIR"

	print_success "ZSH plugins and theme installed successfully"
}

safe_move_dotfiles() {
	print_msg "Moving config files..."

	local config_dir="$USER_HOME/.config"
	local dots_dir="$SCRIPT_DIR/dots"

	if [ ! -d "$dots_dir" ]; then
		print_error "dots directory not found: $dots_dir"
		return 1
	fi

	# Create all backups first, before making any changes
	create_backup "$config_dir" ".backup" || return 1
	create_backup "$USER_HOME/.zshrc" ".backup" || return 1
	create_backup "$USER_HOME/.p10k.zsh" ".backup" || return 1

	BACKUPS_CREATED=true

	# Now proceed with moves
	mkdir -p "$config_dir"

	for item in "$dots_dir"/*; do
		if [ -e "$item" ]; then
			local item_name=$(basename "$item")

			# Handle zsh files
			if [[ "$item_name" == "zshrc" ]]; then
				cp "$item" "$USER_HOME/.zshrc" || return 1
				chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.zshrc"
				print_success "Moved zshrc to $USER_HOME/.zshrc"
				continue
			fi

			if [[ "$item_name" == "p10k.zsh" ]]; then
				cp "$item" "$USER_HOME/.p10k.zsh" || return 1
				chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.p10k.zsh"
				print_success "Moved p10k.zsh to $USER_HOME/.p10k.zsh"
				continue
			fi

			# Handle config files
			if [ -d "$item" ]; then
				cp -r "$item" "$config_dir/" || return 1
			else
				cp "$item" "$config_dir/" || return 1
			fi
			chown -R "$SUDO_USER:$SUDO_USER" "$config_dir/$item_name"
			print_msg "Moved $item_name to $config_dir"
		fi
	done

	DOTFILES_MOVED=true
	print_success "Dotfiles moved successfully"
}

# Modified main function
main() {
	show_banner
	sleep 2

	print_msg "Starting installation..."

	# Each function should return 1 on failure, 0 on success
	update_system || return 1
	enable_multilib || return 1

	# local gpu_choice
	# gpu_choice=$(choose_gpu_driver)
	# install_gpu_driver "$gpu_choice" || return 1

	safe_install_packages || return 1
	# install_paru || return 1
	# install_paru_packages || return 1
	# safe_enable_services || return 1
	safe_move_dotfiles || return 1
	install_zsh_plugins || return 1

	# Mark installation as successful
	INSTALLATION_SUCCESSFUL=true

	print_success "Installation completed successfully!"
}

main
