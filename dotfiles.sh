#!/bin/bash

detect_battery() {
    [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]
}

SHARED_DIR="$HOME/dotfiles/dots/shared/"
if detect_battery; then
    PROFILE_DIR="$HOME/dotfiles/dots/profiles/laptop/"
else
    PROFILE_DIR="$HOME/dotfiles/dots/profiles/desktop/"
fi

echo -e "$PROFILE_DIR $SHARED_DIR"
mkdir -p "$SHARED_DIR" "$PROFILE_DIR"

# rsync options:
# -r: recursive
# -l: copy symlinks as symlinks
# -v: verbose
# -h: human-readable sizes
# --progress: show progress during transfer
# --exclude: exclude specified patterns
RSYNC_OPTS=(-r -l -v -h --progress --exclude='plugins/zsh-*' --exclude='themes/powerlevel10k')

DOTFILES=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/kitty"
    "$HOME/.zshrc"
    "$HOME/.config/nvim"
    "$HOME/.config/rofi"
    "$HOME/.config/zsh"
    "$HOME/.config/fastfetch"
    "$HOME/.config/gtk-2.0"
    "$HOME/.config/gtk-3.0"
    "$HOME/.config/gtk-4.0"
    "$HOME/.p10k.zsh"
)

# Special handling for files that need renaming
special_files=(
    "$HOME/.zshrc:zshrc"
    "$HOME/.p10k.zsh:p10k.zsh"
)

for dotfile in "${DOTFILES[@]}"; do
    base="$(basename "$dotfile")"

    if [[ "$base" == "hypr" || "$base" == "waybar" ]]; then
        target="$PROFILE_DIR"
    else
        target="$SHARED_DIR"
    fi

    if [[ "$dotfile" == "$HOME/.zshrc" || "$dotfile" == "$HOME/.p10k.zsh" ]]; then
        continue
    fi

    if [ -e "$dotfile" ]; then
        rsync "${RSYNC_OPTS[@]}" "$dotfile" "$target/"
    fi
done

for special in "${special_files[@]}"; do
    source_file="${special%:*}"
    dest_name="${special#*:}"
    rsync -l -v -h --progress "$source_file" "$SHARED_DIR$dest_name"
done

echo "Dotfiles backup complete."
