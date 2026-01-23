#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW="\033[1;33m"
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

INSTALLATION_SUCCESSFUL=false
INSTALLATION_STARTED=false
DOTFILES_MOVED=false

BACKUP_LOCATIONS=()

set -eE
trap 'handle_error $? $LINENO' ERR
trap 'final_cleanup' EXIT
trap 'handle_interrupt' INT TERM

if [[ ! -d "$SCRIPT_DIR/logs" ]]; then
	mkdir "$SCRIPT_DIR/logs"
fi

LOG_FILE="$SCRIPT_DIR/logs/install.log"
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

print_warning() {
	echo -e "${BOLD}${YELLOW}[!]${NC} $1"
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
		print_success "System cleanup completed"
		print_warning "Please reboot your system"
	fi
}

cleanup_temp_files() {
	print_msg "Cleaning up temporary files..."

	if [ -d "/tmp/paru" ]; then
		rm -rf /tmp/paru
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
		print_warning "Creating backup: $backup_path"

		cp -r "$source_path" "$backup_path"
		BACKUP_LOCATIONS+=("$source_path:$backup_path")
	fi
}

restore_backups() {
	print_warning "Restoring backups..."

	for backup_entry in "${BACKUP_LOCATIONS[@]}"; do
		IFS=':' read -r original backup <<<"$backup_entry"

		if [ -e "$backup" ]; then
			print_msg "Restoring $original from backup..."

			if [ -f "$original" ]; then
				chattr -i "$original" 2>/dev/null || true
			fi

			rm -rf "$original" 2>/dev/null || true
			mv "$backup" "$original"
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
	exit 1
fi

if [ -z "$SUDO_USER" ]; then
	print_error "SUDO_USER is not set. Run the script using 'sudo -E'."
	exit 1
fi

show_banner() {
	clear

	echo -e "$CYAN"
	printf '%.0s═' {1..80}
	echo -e "$NC"
	echo

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

	echo -e "$CYAN"
	printf '%.0s═' {1..80}
	echo -e "$NC"
	echo
	echo
}

detect_battery() {
	[[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]
}

if detect_battery; then
	PROFILE=laptop
else
	PROFILE=desktop
fi

USER_HOME=$(eval echo ~"$SUDO_USER")

update_system() {
	print_msg "Updating system..."
	pacman -Syu --noconfirm
}

enable_multilib() {
	print_msg "Enabling multilib repository..."

	if grep -q "^\[multilib\]" /etc/pacman.conf; then
		print_msg "Multilib already enabled, skipping..."
		return 0
	fi

	sed -i '/^\#\[multilib\]/,/^\#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf

	pacman -Sy --noconfirm

	print_success "Multilib enabled successfully"
}

install_gpu_drivers() {
	print_msg "Installing GPU drivers..."

	if [[ "$PROFILE" == "laptop" ]]; then
		pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon
		print_success "AMD Vulkan drivers installed"
	else
		pacman -S --needed --noconfirm nvidia nvidia-utils lib32-nvidia-utils
		print_success "NVIDIA drivers installed"
	fi
}

install_packages() {
	print_msg "Installing base packages..."
	INSTALLATION_STARTED=true

	local core_packages=(
		base base-devel git curl wget hyprland hyprlock hyprshot
		hyprpicker hyprpolkitagent waybar wireplumber wl-clipboard
		wtype xdg-desktop-portal-hyprland xdg-utils
	)

	local laptop_packages=(
		tlp tlp-rdw bluez bluez-utils impala powertop iwd
	)

	local application_packages=(
		discord steam firefox ghostty neovim obsidian
		mpv pavucontrol imv yazi
	)

	local font_packages=(
		ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji gnu-free-fonts
	)

	local utility_packages=(
		zsh swww rofi-wayland ffmpeg jq poppler fd fzf zoxide imagemagick
		btop fastfetch go less man-db man-pages npm
		ntfs-3g p7zip ripgrep rsync luarocks tree unzip
		cronie eza bind which
	)

	local groups=("core" "application" "font" "utility")
	[[ "$PROFILE" == "laptop" ]] && groups+=("laptop")

	for group_name in "${groups[@]}"; do
		local -n current_group="${group_name}_packages"

		print_msg "Installing $group_name packages..."

		pacman -S --needed --noconfirm "${current_group[@]}"
		print_success "Successfully installed $group_name packages"
	done
}

enable_services() {
	print_msg "Enabling system services..."

	local system_services=(
		"cronie.service"
		"lm_sensors.service"
		"fstrim.timer"
	)

	local laptop_services=(
		"bluetooth.service"
		"tlp.service"
		"iwd.service"
	)

	local services=("${system_services[@]}")
	[[ "$PROFILE" == "laptop" ]] && services+=("${laptop_services[@]}")

	for service in "${services[@]}"; do
		if ! systemctl list-unit-files "$service" &>/dev/null; then
			print_warning "Service $service not found, skipping..."
			continue
		fi

		print_msg "Enabling $service..."
		systemctl enable --now "$service"
		print_success "Successfully enabled $service!"
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
		git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DIR/zsh-autosuggestions"
		print_success "Installed zsh-autosuggestions"
	else
		print_msg "zsh-autosuggestions already exists, skipping..."
	fi

	if [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
		git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGINS_DIR/zsh-syntax-highlighting"
		print_success "Installed zsh-syntax-highlighting"
	else
		print_msg "zsh-syntax-highlighting already exists, skipping..."
	fi

	if [ ! -d "$THEMES_DIR/powerlevel10k" ]; then
		git clone --depth=1 https://github.com/romkatv/powerlevel10k "$THEMES_DIR/powerlevel10k"
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
	local hypr_dir="$dots_dir/hypr"

	if [ ! -d "$dots_dir" ]; then
		print_error "dots directory not found: $dots_dir"
		exit 1
	fi

	create_backup "$config_dir" ".backup"
	create_backup "$USER_HOME/.zshrc" ".backup"
	create_backup "$USER_HOME/.p10k.zsh" ".backup"
	create_backup "$USER_HOME/.zprofile" ".backup"

	DOTFILES_MOVED=true

	mkdir -p "$config_dir"

	for item in "$dots_dir"/*; do
		[ -e "$item" ] || continue
		local item_name
		item_name=$(basename "$item")

		case "$item_name" in
		hypr)
			if [ ! -d "$hypr_dir" ]; then
				print_error "hypr directory not found: $hypr_dir"
				exit 1
			fi

			mkdir -p "$config_dir/hypr"
			for hypr_item in "$hypr_dir"/*; do
				[ -e "$hypr_item" ] || continue
				local hypr_item_name
				hypr_item_name=$(basename "$hypr_item")

				if [ "$hypr_item_name" = "desktop" ] && [ "$PROFILE" != "desktop" ]; then
					continue
				fi
				if [ "$hypr_item_name" = "laptop" ] && [ "$PROFILE" != "laptop" ]; then
					continue
				fi

				if [ "$hypr_item_name" = "$PROFILE" ] && [ ! -d "$hypr_item" ]; then
					print_error "Profile directory not found: $hypr_item"
					exit 1
				fi

				cp -r "$hypr_item" "$config_dir/hypr/"
			done
			print_msg "Copied hypr directory structure to $config_dir/hypr"
			;;
		zshrc)
			cp "$item" "$USER_HOME/.zshrc"
			chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.zshrc"
			print_msg "Copied zshrc to $USER_HOME/.zshrc"
			;;
		p10k.zsh)
			cp "$item" "$USER_HOME/.p10k.zsh"
			chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.p10k.zsh"
			print_msg "Copied p10k.zsh to $USER_HOME/.p10k.zsh"
			;;
		tlp.conf) ;;
		firefox) ;;
		zprofile)
			cp "$item" "$USER_HOME/.zprofile"
			chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.zprofile"
			print_msg "Copied zprofile to $USER_HOME/.zprofile"
			;;
		*)
			cp -r "$item" "$config_dir/"
			print_msg "Copied $item_name to $config_dir"
			;;
		esac
	done

	chown -R "$SUDO_USER:$SUDO_USER" "$config_dir"

	sed -i "1i\$DEVICE = $PROFILE" "$config_dir/hypr/hyprland.conf"
	print_msg "Added device profile to hyprland.conf"
	print_success "Dotfiles moved successfully"
}

config_dns() {
	print_msg "Configuring DNS..."

	if [[ $PROFILE == "desktop" ]]; then
		systemctl mask \
			systemd-networkd.service \
			systemd-networkd.socket \
			systemd-networkd-varlink.socket \
			systemd-networkd-resolve-hook.socket \
			systemd-resolved.service \
			systemd-resolved-monitor.socket \
			systemd-resolved-varlink.socket

		[ -L /etc/resolv.conf ] && rm /etc/resolv.conf
		[ -f /etc/resolv.conf ] && chattr -i /etc/resolv.conf 2>/dev/null

		printf "nameserver 192.168.0.10\nnameserver 192.168.0.1\n" >/etc/resolv.conf
		chattr +i /etc/resolv.conf

		print_success "DNS configured successfully"

	elif [[ $PROFILE == "laptop" ]]; then

		systemctl enable --now systemd-resolved iwd

		[ -L /etc/resolv.conf ] && rm /etc/resolv.conf
		[ -f /etc/resolv.conf ] && chattr -i /etc/resolv.conf 2>/dev/null

		ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

		mkdir -p /etc/iwd
		cat >/etc/iwd/main.conf <<-'EOF'
			[General]
			EnableNetworkConfiguration=true

			[Network]
			NameResolvingService=systemd
		EOF

		systemctl restart iwd

		print_success "DNS configured successfully"
	fi
}

config_firefox() {
	print_msg "Moving Firefox configuration..."

	local firefox_source="$SCRIPT_DIR/dots/firefox/user.js"
	local firefox_profile
	firefox_profile=$(find "$USER_HOME/.config/mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -n1)

	if [ -z "$firefox_profile" ]; then
		print_msg "Firefox profile not found, creating one..."
		sudo -u "$SUDO_USER" timeout 5 firefox --headless >/dev/null 2>&1 || true
		sleep 2
		firefox_profile=$(find "$USER_HOME/.config/mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -n1)

		if [ -z "$firefox_profile" ]; then
			print_warning "Failed to create Firefox profile, skipping..."
			return 0
		fi
	fi

	cp "$firefox_source" "$firefox_profile/user.js"
	chown "$SUDO_USER:$SUDO_USER" "$firefox_profile/user.js"

	print_success "Firefox configuration moved!"
}

config_xdg() {
	print_msg "Configuring XDG directories and MIME associations..."

	create_backup "$USER_HOME/.config/mimeapps.list" ".backup"

	mkdir -p "$USER_HOME/.cache" "$USER_HOME/.local/share" \
		"$USER_HOME/.local/state" "$USER_HOME/.local/bin"

	chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.cache" "$USER_HOME/.local"

	cat >"$USER_HOME/.config/mimeapps.list" <<-'EOF'
		[Default Applications]
		text/html=firefox.desktop
		x-scheme-handler/http=firefox.desktop
		x-scheme-handler/https=firefox.desktop
		x-scheme-handler/about=firefox.desktop
		text/plain=nvim.desktop
		text/x-python=nvim.desktop
		text/x-shellscript=nvim.desktop
		text/markdown=nvim.desktop
		image/png=imv.desktop
		image/jpeg=imv.desktop
		image/gif=imv.desktop
		image/webp=imv.desktop
		video/mp4=mpv.desktop
		video/x-matroska=mpv.desktop
		video/webm=mpv.desktop
		audio/mpeg=mpv.desktop
		audio/flac=mpv.desktop
		audio/ogg=mpv.desktop
		application/pdf=org.pwmt.zathura-pdf-mupdf.desktop
		inode/directory=thunar.desktop
		[Added Associations]
		text/html=firefox.desktop
		x-scheme-handler/http=firefox.desktop
		x-scheme-handler/https=firefox.desktop
	EOF

	chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.config"

	if [[ ! -d /etc/xdg ]]; then
		print_warning "No /etc/xdg directory, creating one..."
		mkdir /etc/xdg
	fi

	cp "$SCRIPT_DIR/dots/xdg/user-dirs.conf" "$SCRIPT_DIR/dots/xdg/user-dirs.defaults" "/etc/xdg/"
	sudo -u "$SUDO_USER" xdg-user-dirs-update
	print_success "XDG configuration completed"
}

config_fonts() {
	print_msg "Installing fonts..."

	local fonts_source="$SCRIPT_DIR/fonts"
	local fonts_dest="$USER_HOME/.local/share/fonts"

	if [ ! -d "$fonts_source" ]; then
		print_warning "fonts directory not found: $fonts_source, skipping..."
		return 0
	fi

	mkdir -p "$fonts_dest"

	for font_zip in "$fonts_source"/*.zip; do
		[ -e "$font_zip" ] || continue

		local font_name
		font_name=$(basename "$font_zip" .zip)

		print_msg "Extracting $font_name..."
		unzip -oq "$font_zip" -d "$fonts_dest"
	done

	chown -R "$SUDO_USER:$SUDO_USER" "$fonts_dest"

	sudo -u "$SUDO_USER" fc-cache -f

	print_success "Fonts installed successfully"
}

config_autologin() {
	print_msg "Configuring autologin..."

	mkdir -p /etc/systemd/system/getty@tty1.service.d

	cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $SUDO_USER %I \$TERM
EOF

	systemctl daemon-reload

	print_success "Autologin configured"
}

config_grub() {
	print_msg "Configuring GRUB..."

	if ! command -v grub-mkconfig &>/dev/null; then
		print_error "GRUB not installed, skipping GRUB configuration"
		return 0
	fi

	create_backup "/etc/default/grub" ".backup"

	if grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
		sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
	else
		echo "GRUB_TIMEOUT=0" >>/etc/default/grub
	fi

	grub-mkconfig -o /boot/grub/grub.cfg
	print_success "GRUB configured successfully"
}

config_power_management() {
	print_msg "Configuring power management..."

	print_warning "Masking unrequired services..."
	systemctl mask systemd-rfkill.service systemd-rfkill.socket

	create_backup "/etc/tlp.conf" ".backup"

	cat >/etc/tlp.conf <<-'EOF'
		TLP_ENABLE=1
		TLP_AUTO_SWITCH=2
		DISK_IDLE_SECS_ON_AC=0
		DISK_IDLE_SECS_ON_BAT=2
		CPU_SCALING_GOVERNOR_ON_AC=performance
		CPU_SCALING_GOVERNOR_ON_BAT=powersave
		CPU_SCALING_GOVERNOR_ON_SAV=powersave
		CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
		CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
		CPU_ENERGY_PERF_POLICY_ON_SAV=power
		CPU_BOOST_ON_AC=1
		CPU_BOOST_ON_BAT=1
		CPU_BOOST_ON_SAV=0
		PLATFORM_PROFILE_ON_AC=performance
		PLATFORM_PROFILE_ON_BAT=balanced
		PLATFORM_PROFILE_ON_SAV=low-power
		DISK_DEVICES="nvme0n1"
		WIFI_PWR_ON_AC=off
		WIFI_PWR_ON_BAT=on
		PCIE_ASPM_ON_AC=default
		PCIE_ASPM_ON_BAT=powersave
		RUNTIME_PM_ON_AC=on
		RUNTIME_PM_ON_BAT=auto
	EOF

	if ! grep -q "amd_pstate=active" /etc/default/grub; then
		create_backup "/etc/default/grub" ".backup"
		sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&amd_pstate=active /' /etc/default/grub
		print_msg "Added amd_pstate=active to GRUB_CMDLINE_LINUX_DEFAULT"
	else
		print_msg "amd_pstate already configured, skipping..."
	fi

	systemctl restart tlp
	print_success "Power management configured successfully"
}

main() {
	show_banner
	sleep 2

	print_msg "Starting installation..."

	update_system
	enable_multilib
	install_gpu_drivers
	install_packages
	enable_services
	move_dotfiles
	install_zsh_plugins
	chsh -s /usr/bin/zsh "$SUDO_USER"
	config_dns
	config_fonts
	config_xdg
	config_firefox

	if [[ "$PROFILE" == "desktop" ]]; then
		config_autologin
	fi

	if [[ "$PROFILE" == "laptop" ]]; then
		config_power_management
	fi

	config_grub

	INSTALLATION_SUCCESSFUL=true
	print_success "Installation completed successfully!"
}

main
