#!/bin/bash

# TODO: Add input for resolution and monitors
# TODO: Error handling (particularly if anything fails mid way)
# TODO: Ensure the permissions are not broad

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

trap cleanup EXIT
trap cleanup SIGINT
trap cleanup SIGTERM
trap cleanup SIGHUP

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

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
	print_error "Please run as sudo."
	exit 1
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
		exit 1
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
		exit 1
	}

	print_success "Multilib enabled successfully"
}

install_packages() {
	print_msg "Installing base packages..."
	pacman -S --needed --noconfirm \
		base \
		base-devel \
		alsa-utils \
		inetutils \
		reflector \
		aria2 \
		dmidecode \
		dnsmasq \
		dosfstools \
		dysk \
		evtest \
		gamemode \
		lib32-gamemode \
		exfat-utils \
		git \
		ly \
		hyprland \
		hyprlock \
		hyprpaper \
		hyprshot \
		hyprpicker \
		hyprpolkitagent \
		waybar \
		wireplumber \
		wl-clipboard \
		wtype \
		xdg-desktop-portal-hyprland \
		xdg-utils \
		ttf-jetbrains-mono-nerd \
		noto-fonts \
		noto-fonts-emoji \
		zsh \
		discord \
		steam \
		swww \
		wget \
		curl \
		neovim \
		openvpn \
		imv \
		rofi-wayland \
		yazi \
		ffmpeg \
		jq \
		poppler \
		fd \
		fzf \
		zoxide \
		imagemagick \
		btop \
		fastfetch \
		firefox \
		kitty \
		gnu-free-fonts \
		go \
		gparted \
		less \
		man-db \
		man-pages \
		npm \
		ntfs-3g \
		obsidian \
		p7zip \
		pavucontrol \
		ripgrep \
		rsync \
		luarocks \
		tree \
		unzip \
		cronie \
		lm_sensors \
		vlc || {
		print_error "Failed to install packages"
		exit 1
	}
}

install_driver() {
	print_msg "Installing $1..."
	if pacman -S --noconfirm --needed "$1"; then
		print_success "Successfully installed $1"
	else
		print_error "Failed to install $1"
		exit 1
	fi
}

install_vm_driver() {
	if grep -q 'QEMU' /sys/class/dmi/id/product_name 2>/dev/null; then
		print_msg "QEMU VM detected, installing virtio video driver..."
		pacman -S --noconfirm --needed xf86-video-virtio || {
			print_error "Failed to install xf86-video-virtio"
			exit 1
		}
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
		read -rp "Is this correct? [y/N]: " confirm
		if [[ "$confirm" =~ ^[Yy]$ ]]; then
			choice=$detected_choice
		else
			choice=$(manual_choice)
		fi
	else
		print_msg "Could not auto-detect GPU."
		choice=$(manual_choice)
	fi

	echo "$choice"
}

install_gpu_driver() {
	if install_vm_driver; then
		return
	fi

	local choice=$1

	case $choice in
	1)
		install_driver linux-headers
		install_driver dkms
		install_driver nvidia-dkms
		install_driver nvidia-settings
		install_driver lib32-nvidia-utils
		;;
	2)
		install_driver linux-headers
		install_driver xf86-video-amdgpu
		install_driver lib32-mesa
		install_driver lib32-vulkan-radeon
		;;
	3)
		install_driver linux-headers
		install_driver xf86-video-intel
		install_driver lib32-mesa
		install_driver lib32-vulkan-intel
		;;
	*)
		print_error "Invalid GPU choice: $choice"
		exit 1
		;;
	esac
}

install_paru() {
	print_msg "Installing paru..."
	if ! command -v paru &>/dev/null; then
		cd /tmp || exit
		git clone https://aur.archlinux.org/paru.git || {
			print_error "Failed to clone paru"
			exit 1
		}
		chown -R "$SUDO_USER:$SUDO_USER" paru
		cd paru || exit
		sudo -u "$SUDO_USER" makepkg -si --noconfirm || {
			print_error "Failed to install paru"
			exit 1
		}
		print_success "Successfully installed paru!"
		cd ..
		rm -rf paru
	else
		print_msg "paru is already installed"
	fi
}

install_paru_packages() {
	print_msg "Installing paru packages..."
	sudo -u "$SUDO_USER" paru -S --needed --noconfirm \
		qdirstat \
		nvibrant-bin \
		noisetorch || {
		print_error "Failed to install paru packages"
		exit 1
	}
	print_success "Successfully installed paru packages!"
}

enable_services() {
	print_msg "Enabling system services..."
	systemctl enable --now NetworkManager ly.service cronie.service lm_sensors.service bluetooth.service fstrim.timer || {
		print_error "Failed to enable system services"
		exit 1
	}

	print_msg "Enabling user services..."
	sudo -u "$SUDO_USER" systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service || {
		print_error "Failed to enable user services"
		exit 1
	}

	print_success "Services enabled successfully"
}

move_dotfiles() {
	print_msg "Moving config files..."
	CONFIG_DIR="$USER_HOME/.config"
	DOTS_DIR="$SCRIPT_DIR/dots"

	if [ ! -d "$DOTS_DIR" ]; then
		print_error "dots directory not found: $DOTS_DIR"
		return 1
	fi

	if [ -d "$CONFIG_DIR" ]; then
		print_msg "Backing up existing config..."
		cp -r "$CONFIG_DIR" "$USER_HOME/.config.backup"
	fi

	mkdir -p "$CONFIG_DIR"

	for item in "$DOTS_DIR"/*; do
		if [ -e "$item" ]; then
			item_name=$(basename "$item")

			if [ -d "$item" ]; then
				cp -r "$item" "$CONFIG_DIR/" || {
					print_error "Failed to copy $item_name"
					return 1
				}
			else
				cp "$item" "$CONFIG_DIR/" || {
					print_error "Failed to copy $item_name"
					return 1
				}
			fi
			chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR/$item_name"
			echo "Moved $item_name to $CONFIG_DIR"
		fi
	done

	print_msg "Previous ~/.config moved to ~/.config.backup"
	print_success "Dotfiles moved successfully"
}

move_zsh_config() {
	for dotfile in ".zshrc" ".p10k.zsh"; do
		SOURCE_PATH="$SCRIPT_DIR/$dotfile"
		if [ -f "$SOURCE_PATH" ]; then
			cp "$SOURCE_PATH" "$USER_HOME/"
			chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/$dotfile"
			echo "Moved $dotfile to $USER_HOME"
		else
			print_error "$dotfile not found in $SCRIPT_DIR, skipping..."
		fi
	done
}

cleanup() {
	print_msg "Cleaning up..."

	if [ -d "/tmp/paru" ]; then
		print_msg "Removing paru build directory..."
		rm -rf /tmp/paru
	fi

	if [ -d "$USER_HOME/.config.backup" ]; then
		print_msg "Found backup config, restoring..."
		rm -rf "$USER_HOME/.config"
		mv "$USER_HOME/.config.backup" "$USER_HOME/.config"
		chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.config"
	fi

	# Clean up any partial package installations
	print_msg "Cleaning package cache..."
	pacman -Sc --noconfirm >/dev/null 2>&1

	# Kill any hanging package manager processes
	if pgrep -x "pacman" >/dev/null; then
		print_msg "Killing hanging pacman processes..."
		pkill -x pacman
	fi

	# Remove pacman lock if it exists
	if [ -f "/var/lib/pacman/db.lck" ]; then
		print_msg "Removing pacman lock file..."
		rm -f /var/lib/pacman/db.lck
	fi

	# Reset to original directory
	cd "$SCRIPT_DIR" 2>/dev/null || true

	print_msg "Cleanup completed"
}

main() {
	show_banner
	sleep 2
	print_msg "Starting installation..."
	update_system
	enable_multilib
	local gpu_choice
	gpu_choice=$(choose_gpu_driver)
	install_gpu_driver "$gpu_choice"
	install_packages
	install_paru
	install_paru_packages
	enable_services
	move_dotfiles
	install_extras
	move_zsh_config

	print_success "Installation completed!"
	print_msg "Please reboot your system"
}

main
