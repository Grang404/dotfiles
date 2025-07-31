#!/bin/bash

# TODO: ignore install.sh and README.md
# TODO: Add input for resolution and display drivers maybe?
# TODO: Error handling for failed mid way
# TODO: Fix polkit (use hyprpol?)
# TODO: Error handling for service enables
# TODO: Ensure the permissions are not broad
# TODO: Check for disk space
# TODO: ADD MULTILIB
# TODO: Syncthing?

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

USER_HOME=$(eval echo ~"$SUDO_USER")

update_system() {
	print_msg "Updating system..."
	pacman -Syu --noconfirm || {
		print_error "Failed to update system."
		exit 1
	}
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
		;;
	2)
		install_driver linux-headers
		install_driver xf86-video-amdgpu
		;;
	3)
		install_driver linux-headers
		install_driver xf86-video-intel
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
	print_msg "Enabling services..."
	systemctl enable --now NetworkManager ly.service cronie.service lm_sensors.service || {
		print_error "Failed to enable services"
		exit 1
	}
}

move_dotfiles() {
	print_msg "Moving config files..."
	CONFIG_DIR="$USER_HOME/.config"

	mkdir -p "$CONFIG_DIR"

	dirs_to_move_to_config=("hypr" "waybar" "kitty" "btop" "nvim" "../dotfiles.sh" "gtk-2.0" "gtk-3.0" "gtk-4.0" "oh-my-zsh" "fastfetch" "rofi")

	for dir in "${dirs_to_move_to_config[@]}"; do
		SOURCE_PATH="$SCRIPT_DIR/$dir"
		if [ -e "$SOURCE_PATH" ]; then
			if [ -d "$SOURCE_PATH" ]; then
				cp -r "$SOURCE_PATH" "$CONFIG_DIR/"
			else
				cp "$SOURCE_PATH" "$CONFIG_DIR/"
			fi
			chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR/$dir"
			echo "Moved $dir to $CONFIG_DIR"
		else
			print_error "$dir not found in $SCRIPT_DIR, skipping..."
		fi
	done
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
	print_msg "Cleaning up temporary files..."
	rm -rf /tmp/paru
}

main() {
	print_msg "Starting installation..."
	update_system

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
	cleanup
	print_success "Installation completed!"
	print_msg "Please reboot your system"
}

main
