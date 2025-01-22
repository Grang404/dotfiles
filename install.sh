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
        xorg xorg-server \
	ly \
	awesome \
	zsh \
        git \
        wget \
        curl \
	nvim \
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
	polkit-qt \
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
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        chown -R "$SUDO_USER:$SUDO_USER" yay
        cd yay
        sudo -u "$SUDO_USER" makepkg -si --noconfirm
        cd ..
        rm -rf yay
    else
        print_msg "yay is already installed"
    fi
}

install_yay_packages(){
    print_msg "Installing yay packages..."
    sudo -u "$SUDO_USER" yay -S --needed --noconfirm \
	betterlockscreen \
	qdirstat \
	vesktop \
	spotify \
	nerd-fonts-complete
}


# Enable necessary services
enable_services() {
    print_msg "Enabling services..."
    systemctl enable NetworkManager
    systemctl enable ly.service
    systemctl enable polkit.service

}

move_dotfiles() {
    print_msg "Moving config files..."
    SOURCE_DIR="$(pwd)"
    CONFIG_DIR="$HOME/.config"
    AWESOME_THEME_DIR="$CONFIG_DIR/awesome/themes"

    dirs_to_move_to_config=("kitty" "picom" "btop" "nvim" "ranger" "vesktop" "autostart" "dotfiles.sh" "gtk-3.0" "oh-my-zsh" "README.md" "awesome" "fastfetch" "install.sh" "rofi")

    # Move dot files to $HOME/.config
    for dir in "${dirs_to_move_to_config[@]}"; do
	if [ -d "$SOURCE_DIR/$dir" ]; then
	    mv "$SOURCE_DIR/$dir" "$CONFIG_DIR"
	    echo "Moved $dir to $CONFIG_DIR"
	else
	    echo "$dir not found, skipping..."
	fi
    done

    # Move .zshrc and .p10k.zsh to $HOME
    if [ -f "$SOURCE_DIR/.zshrc" ]; then
	mv "$SOURCE_DIR/.zshrc" "$HOME"
	echo "Moved .zshrc to $HOME"
    else
	echo ".zshrc not found, skipping..."
    fi

    if [ -f "$SOURCE_DIR/.p10k.zsh" ]; then
	mv "$SOURCE_DIR/.p10k.zsh" "$HOME"
	echo "Moved .p10k.zsh to $HOME"
    else
	echo ".p10k.zsh not found, skipping..."
    fi

    # Move samurai to .config/awesome/themes
    if [ -d "$SOURCE_DIR/samurai" ]; then
	mkdir -p "$AWESOME_THEME_DIR"
	mv "$SOURCE_DIR/samurai" "$AWESOME_THEME_DIR"
	echo "Moved samurai to $AWESOME_THEME_DIR"
    else
	echo "samurai directory not found, skipping..."
    fi

}

install_extras() {

    sudo -u "$SUDO_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sudo -u "$SUDO_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.config/oh-my-zsh/custom}/themes/powerlevel10k
    sudo -u "$SUDO_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.config/oh-my-zsh/plugins/"
    sudo -u "$SUDO_USER" git clone https://github.com/marlonrichert/zsh-autocomplete.git "$HOME/.config/oh-my-zsh/plugins/"
}

install_p10k() {


}

# Main installation flow
main() {
    print_msg "Starting installation..."
    update_system
    install_packages
    install_yay
    install_yay_packages
    enable_services
    move_dotfiles
    install_extras
    print_success "Installation completed!"
    print_msg "Please reboot your system"
}

main
