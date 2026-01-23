move_dotfiles() {
	print_msg "Moving config files..."
	local config_dir="$USER_HOME/.config"
	local dots_dir="$SCRIPT_DIR/dots"
	local hypr_dir="$dots_dir/hypr"

	if [ ! -d "$dots_dir" ]; then
		print_error "dots directory not found: $dots_dir"
		exit 1
	fi

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
