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
DOTFILES_MOVED=false

BACKUP_LOCATIONS=()

set -eE
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

rollback_installation() {
	print_error "Rolling back installation due to failure..."

	if [[ "$DOTFILES_MOVED" == true ]]; then
		restore_backups
	fi

	print_msg "Packages left installed (removing them could cause issues)"
	print_msg "If you want to remove packages, run: pacman -Rns [package_names]"

	cleanup_temp_files
	cleanup_package_manager

	print_error "Rollback completed"
}

if [ "$EUID" -ne 0 ]; then
	print_error "Please run as sudo."
	false
fi

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

install_packages() {
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

	for group_name in "core" "system" "desktop" "application" "font" "utility"; do
		local -n current_group="${group_name}_packages"

		print_msg "Installing $group_name packages..."

		if pacman -S --needed --noconfirm "${current_group[@]}"; then
			print_success "Successfully installed $group_name packages"
		else
			print_error "Failed to install $group_name packages"
			return 1
		fi
	done

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
		# nvibrant-bin TEST: READD THIS FOR MAINSCRIPTO OR POP OUT FOR MULTIPLE CONFIGS
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

enable_services() {
	print_msg "Enabling system services..."

	local system_services=(
		"NetworkManager"
		"ly.service"
		"cronie.service"
		# "lm_sensors.service" TEST:
		# "bluetooth.service"
		# "fstrim.timer"
	)

	for service in "${system_services[@]}"; do
		print_msg "Enabling $service..."
		if systemctl enable --now "$service"; then
			print_success "Successfully enabled $service!"
		else
			print_error "Failed to enable $service"
			return 1
		fi
	done

	print_success "Services enabled successfully!"
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

	if [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
		git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGINS_DIR/zsh-syntax-highlighting" || {
			print_error "Failed to install zsh-syntax-highlighting"
			return 1
		}
		print_success "Installed zsh-syntax-highlighting"
	else
		print_msg "zsh-syntax-highlighting already exists, skipping..."
	fi

	if [ ! -d "$THEMES_DIR/powerlevel10k" ]; then
		git clone --depth=1 https://github.com/romkatv/powerlevel10k "$THEMES_DIR/powerlevel10k" || {
			print_error "Failed to install powerlevel10k"
			return 1
		}
		print_success "Installed powerlevel10k theme"
	else
		print_msg "powerlevel10k already exists, skipping..."
	fi

	chown -R "$SUDO_USER:$SUDO_USER" "$ZSH_CONFIG_DIR"

	print_success "ZSH plugins and theme installed successfully"
}

move_dotfiles() {
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

	mkdir -p "$config_dir"

	for item in "$dots_dir"/*; do
		if [ -e "$item" ]; then
			local item_name
			item_name=$(basename "$item")

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
	install_packages || return 1
	install_paru || return 1
	install_paru_packages || return 1
	enable_services || return 1
	move_dotfiles || return 1
	install_zsh_plugins || return 1

	INSTALLATION_SUCCESSFUL=true

	print_success "Installation completed successfully!"
}

main
