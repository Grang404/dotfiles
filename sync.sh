#!/bin/bash

set -o pipefail

readonly DOTFILES_ROOT="$HOME/dotfiles"
readonly DOTS_DIR="$DOTFILES_ROOT/dots"
readonly LOG_DIR="$DOTFILES_ROOT/logs"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

LOG_FILE=""

log() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    if [[ -n "$LOG_FILE" ]]; then
        echo "$msg" >>"$LOG_FILE"
    fi
}

error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    log "ERROR: $*"
    exit 1
}

warn() {
    echo -e "${YELLOW}WARNING: $*${NC}" >&2
    log "WARNING: $*"
}

success() {
    echo -e "${GREEN}$*${NC}"
    log "$*"
}

check_dependencies() {
    local deps=("rsync")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            error "$dep is not installed. Please install it first."
        fi
    done
}

setup_directories() {
    mkdir -p "$DOTS_DIR" "$LOG_DIR" || error "Failed to create directories"

    LOG_FILE="$LOG_DIR/sync-$(date +%Y%m%d-%H%M%S).log"
    log "Directories initialized"
}

sync_directory() {
    local source="$1"
    local target="$2"
    local name
    name="$(basename "$source")"
    if [[ ! -e "$source" ]]; then
        warn "Skipping $name - source does not exist: $source"
        return 1
    fi
    log "Syncing $name"
    mkdir -p "$(dirname "$target")"
    local rsync_output
    local rsync_opts=(-a -v -h --progress --delete)

    if [[ "$name" == "zsh" ]]; then
        rsync_opts+=(--exclude='plugins/' --exclude='themes/')
    fi

    if [[ "$name" == "hypr" ]]; then
        rsync_opts+=(--exclude='laptop/' --exclude='desktop/')
    fi

    if [[ -d "$source" ]]; then
        if rsync_output=$(rsync "${rsync_opts[@]}" "$source/" "$target/" 2>&1); then
            log "$rsync_output"
            success "Synced $name"
            return 0
        fi
    else
        if rsync_output=$(rsync "${rsync_opts[@]}" "$source" "$target" 2>&1); then
            log "$rsync_output"
            success "Synced $name"
            return 0
        fi
    fi

    log "$rsync_output"
    warn "Failed to sync $name"
    return 1
}

main() {
    local sync_count=0 fail_count=0

    log "=== Dotfiles Sync Started ==="

    check_dependencies
    setup_directories

    local -a config_dirs=(
        "hypr"
        "waybar"
        "eza"
        "ghostty"
        "nvim"
        "rofi"
        "zsh"
        "fastfetch"
        "btop"
        "gtk-2.0"
        "gtk-3.0"
        "gtk-4.0"
    )

    log "=== Syncing Config Directories ==="
    for dir in "${config_dirs[@]}"; do
        if sync_directory "$HOME/.config/$dir" "$DOTS_DIR/$dir"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    done

    log "=== Syncing Home Dotfiles ==="
    if sync_directory "$HOME/.zshrc" "$DOTS_DIR/zshrc"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    if sync_directory "$HOME/.p10k.zsh" "$DOTS_DIR/p10k.zsh"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    if sync_directory "$HOME/.zprofile" "$DOTS_DIR/zprofile"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    if [[ -f "$DOTS_DIR/hypr/hyprland.conf" ]]; then
        log "Trimming first 2 lines from hyprland.conf"
        sed -i '1,2d' "$DOTS_DIR/hypr/hyprland.conf"
        success "Trimmed hyprland.conf"
    fi

    log "=== Syncing Firefox Config ==="
    local firefox_profile
    firefox_profile=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -n1)

    if [[ -n "$firefox_profile" && -f "$firefox_profile/user.js" ]]; then
        if sync_directory "$firefox_profile/user.js" "$DOTS_DIR/firefox/user.js"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    else
        warn "Firefox user.js not found, skipping..."
    fi

    log "=== Sync Complete ==="
    log "Successfully synced: $sync_count items"
    [[ $fail_count -gt 0 ]] && warn "Failed/Skipped: $fail_count items"
    success "Dotfiles sync completed successfully!"
    log "Log saved to: $LOG_FILE"
}

main "$@"
