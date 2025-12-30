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
        echo "$msg" | tee -a "$LOG_FILE"
    else
        echo "$msg"
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

detect_device() {
    if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
        echo "laptop"
    else
        echo "desktop"
    fi
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
    mkdir -p "$DOTS_DIR/desktop" "$DOTS_DIR/laptop" "$LOG_DIR" || error "Failed to create directories"

    LOG_FILE="$LOG_DIR/backup-$(date +%Y%m%d-%H%M%S).log"
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

    mkdir -p "$target"

    local rsync_output
    if [[ -d "$source" ]]; then
        if rsync_output=$(rsync -r -l -v -h --progress \
            --exclude='plugins/' \
            --exclude='themes/' \
            "$source/" "$target/" 2>&1); then
            echo "$rsync_output" | tee -a "$LOG_FILE"
            success "✓ Synced $name"
            return 0
        fi
    else
        if rsync_output=$(rsync -l -v -h --progress "$source" "$target" 2>&1); then
            echo "$rsync_output" | tee -a "$LOG_FILE"
            success "✓ Synced $name"
            return 0
        fi
    fi

    echo "$rsync_output" | tee -a "$LOG_FILE"
    warn "Failed to sync $name"
    return 1
}

main() {
    local sync_count=0 fail_count=0

    log "=== Dotfiles Sync Started ==="

    check_dependencies

    local device
    device=$(detect_device)
    log "Detected device: $device"

    setup_directories

    local device_dir="$DOTS_DIR/$device"

    local -a config_dirs=(
        "hypr"
        "waybar"
        "kitty"
        "nvim"
        "rofi"
        "zsh"
        "fastfetch"
        "gtk-2.0"
        "gtk-3.0"
        "gtk-4.0"
    )

    log "=== Syncing Config Directories to $device ==="
    for dir in "${config_dirs[@]}"; do
        if sync_directory "$HOME/.config/$dir" "$device_dir/$dir"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    done

    log "=== Syncing Home Dotfiles ==="
    if [[ -f "$HOME/.zshrc" ]]; then
        mkdir -p "$device_dir"
        log "Syncing .zshrc"
        local rsync_output
        if rsync_output=$(rsync -l -v -h --progress "$HOME/.zshrc" "$device_dir/zshrc" 2>&1); then
            echo "$rsync_output" | tee -a "$LOG_FILE"
            success "✓ Synced .zshrc"
            ((sync_count++))
        else
            echo "$rsync_output" | tee -a "$LOG_FILE"
            warn "Failed to sync .zshrc"
            ((fail_count++))
        fi
    fi

    if [[ -f "$HOME/.p10k.zsh" ]]; then
        log "Syncing .p10k.zsh"
        local rsync_output
        if rsync_output=$(rsync -l -v -h --progress "$HOME/.p10k.zsh" "$device_dir/p10k.zsh" 2>&1); then
            echo "$rsync_output" | tee -a "$LOG_FILE"
            success "✓ Synced .p10k.zsh"
            ((sync_count++))
        else
            echo "$rsync_output" | tee -a "$LOG_FILE"
            warn "Failed to sync .p10k.zsh"
            ((fail_count++))
        fi
    fi

    log "=== Sync Complete ==="
    log "Successfully synced: $sync_count items"
    [[ $fail_count -gt 0 ]] && warn "Failed/Skipped: $fail_count items"
    success "Dotfiles sync completed successfully!"
    log "Log saved to: $LOG_FILE"
}

main "$@"
