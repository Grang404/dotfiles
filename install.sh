#!/bin/bash

# TODO: ignore install.sh and README.md
# TODO: Add input for resolution and display drivers maybe?

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Log output
LOG_FILE="$SCRIPT_DIR/install_script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Print colored output
print_msg() {
	echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
	echo -e "${RED}[!]${NC} $1"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
	print_error "Please run as root"
	exit 1
fi

# Check if SUDO_USER is set
if [ -z "$SUDO_USER" ]; then
	print_error "SUDO_USER is not set. Run the script using 'sudo -E'."
	exit 1
fi

# Get the home directory of the sudo user
USER_HOME=$(eval echo ~"$SUDO_USER")

update_system() {
	print_msg "Updating system..."
	pacman -Syu --noconfirm || {
		print_error "Failed to update system"
		exit 1
	}
}

install_packages() {
	print_msg "Installing base packages..."
	pacman -S --needed --noconfirm \
		base base-devel \
		ly \
		xorg-server \
		xorg-xinit \
		xorg-xrandr \
		xorg-xprop \
		xorg-xinput \
		awesome \
		zsh \
		git \
		wget \
		curl \
		neovim \
		openvpn \
		feh \
		rofi \
		ranger \
		btop \
		fastfetch \
		firefox \
		kitty \
		nitrogen \
		flameshot \
		gnu-free-fonts \
		go \
		gparted \
		gpick \
		less \
		man-db \
		man-pages \
		npm \
		ntfs-3g \
		obsidian \
		p7zip \
		picom \
		pavucontrol \
		polkit-gnome \
		ripgrep \
		rsync \
		tree \
		unzip \
		vlc \
		xclip \
		xdg-utils || {
		print_error "Failed to install packages"
		exit 1
	}
}

# Install and configure yay
install_yay() {
	print_msg "Installing yay..."
	if ! command -v yay &>/dev/null; then
		cd /tmp
		git clone https://aur.archlinux.org/yay.git || {
			print_error "Failed to clone yay"
			exit 1
		}
		chown -R "$SUDO_USER:$SUDO_USER" yay
		cd yay
		sudo -u "$SUDO_USER" makepkg -si --noconfirm || {
			print_error "Failed to install yay"
			exit 1
		}
		cd ..
		rm -rf yay
	else
		print_msg "yay is already installed"
	fi
}

install_yay_packages() {
	print_msg "Installing yay packages..."
	sudo -u "$SUDO_USER" yay -S --needed --noconfirm \
		betterlockscreen \
		qdirstat \
		vesktop \
		spotify \
		nerd-fonts-complete || {
		print_error "Failed to install yay packages"
		exit 1
	}
}

# Enable necessary services
enable_services() {
	print_msg "Enabling services..."
	systemctl enable --now NetworkManager ly.service polkit.service || {
		print_error "Failed to enable services"
		exit 1
	}
}

# Move dotfiles to $HOME/.config
move_dotfiles() {
	print_msg "Moving config files..."
	CONFIG_DIR="$USER_HOME/.config"
	AWESOMES_DIR="$CONFIG_DIR/awesome/themes"

	mkdir -p "$CONFIG_DIR"

	dirs_to_move_to_config=("kitty" "picom" "btop" "nvim" "ranger" "vesktop" "autostart" "dotfiles.sh" "gtk-3.0" "oh-my-zsh" "awesome" "fastfetch" "rofi")

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

	WALLPAPER_SOURCE="$SCRIPT_DIR/samurai_wallpaper.png"
	if [ -f "$WALLPAPER_SOURCE" ]; then
		mkdir -p "$AWESOMES_DIR"
		cp "$WALLPAPER_SOURCE" "$AWESOMES_DIR/"
		chown -R "$SUDO_USER:$SUDO_USER" "$AWESOMES_DIR/samurai_wallpaper.png"
		print_msg "Moved samurai_wallpaper.png to $AWESOMES_DIR"
	else
		print_error "Wallpaper not found in $SCRIPT_DIR, skipping..."
	fi
}

install_extras() {
	print_msg "Installing extras..."
	sudo -u "$SUDO_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.config/oh-my-zsh/themes/powerlevel10k"
	sudo -u "$SUDO_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$USER_HOME/.config/oh-my-zsh/plugins/zsh-autosuggestions"
	sudo -u "$SUDO_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting "$USER_HOME/.config/oh-my-zsh/plugins/zsh-syntax-highlighting"
	sudo -u "$SUDO_USER" sh -c "RUNZSH=no CHSH=no $(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
	rm -rf /tmp/yay
}

main() {
	print_msg "Starting installation..."
	update_system
	install_packages
	install_yay
	install_yay_packages
	enable_services
	move_dotfiles
	install_extras
	move_zsh_config
	cleanup
	print_success "Installation completed!"
	print_msg "Please reboot your system"
}

main
