#!/bin/bash

detect_battery() {
    [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]
}

if ! command -v rsync >/dev/null; then
    echo "rsync not found"
    exit 1
fi

SHARED_DIR="$HOME/dotfiles/dots/shared/"

if detect_battery; then
    PROFILE_DIR="$HOME/dotfiles/dots/profiles/laptop/"
else
    PROFILE_DIR="$HOME/dotfiles/dots/profiles/desktop/"
fi

mkdir -p "$SHARED_DIR" "$PROFILE_DIR"

echo "1) Full sync"
echo "2) Profile-only"
read -r mode

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

special_files=(
    "$HOME/.zshrc:zshrc"
    "$HOME/.p10k.zsh:p10k.zsh"
)

for dotfile in "${DOTFILES[@]}"; do
    base="$(basename "$dotfile")"

    if [[ "$base" == "hypr" || "$base" == "waybar" ]]; then
        target="$PROFILE_DIR"
    else
        [[ "$mode" == "2" ]] && continue
        target="$SHARED_DIR"
    fi

    if [[ "$dotfile" == "$HOME/.zshrc" || "$dotfile" == "$HOME/.p10k.zsh" ]]; then
        continue
    fi

    [ -e "$dotfile" ] && rsync "${RSYNC_OPTS[@]}" "$dotfile" "$target/"
done

for special in "${special_files[@]}"; do
    source_file="${special%:*}"
    dest_name="${special#*:}"

    [[ "$mode" == "2" ]] && continue

    rsync -l -v -h --progress "$source_file" "$SHARED_DIR$dest_name"
done

echo "Dotfiles backup complete."
