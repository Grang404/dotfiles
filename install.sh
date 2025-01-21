#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Update system first
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
	xorg-server \
	x-org-xinit \
	x-org-xrandr \
	x-org-xinput \
        git \
        wget \
        curl \
        xorg xorg-server \
        networkmanager \
	nvim \
	zsh \
	openvpn \
	feh \
	betterlockscreen \
	rofi \
	ranger \
	btop \
	fastfetch \
	firefox \
	kitty \
	nitrogen \
	awesome \
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
	polkit-qt \
	qdirstat \
	ripgrep \
	rsync \
	tree \
	unzip \
	vlc \
	xclip \
	xdg-utils \
	

        || {
            print_error "Failed to install packages"
            exit 1
        }
}

# Install and configure yay
install_yay() {
    print_msg "Installing yay..."
    # Check if yay is already installed
    if ! command -v yay &> /dev/null; then
        # Switch to regular user for building yay
        regular_user=$(whoami)
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        chown -R "$regular_user:$regular_user" yay
        cd yay
        sudo -u "$regular_user" makepkg -si --noconfirm
        cd ..
        rm -rf yay
    else
        print_msg "yay is already installed"
    fi
}

    # Add additional software here
    # For AUR packages, use:
    # sudo -u "$regular_user" yay -S --needed --noconfirm package-name
}

# Enable necessary services
enable_services() {
    print_msg "Enabling services..."
    systemctl enable NetworkManager
    # Add other services as needed
}

# Main installation flow
main() {
    print_msg "Starting installation..."
    update_system
    install_packages
    install_yay
    enable_services
    move_dirs
    
    print_success "Installation completed!"
    print_msg "Please reboot your system"
}

main
