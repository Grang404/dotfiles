#!/bin/bash

set -o pipefail

# Configuration
readonly DOTFILES_ROOT="$HOME/dotfiles"
readonly DOTS_DIR="$DOTFILES_ROOT/dots"
readonly SHARED_DIR="$DOTS_DIR/shared"
readonly LOG_DIR="$DOTFILES_ROOT/logs"

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

LOG_FILE=""

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
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
    local device="$1"
    mkdir -p "$SHARED_DIR" \
        "$DOTS_DIR/hypr/shared" \
        "$DOTS_DIR/hypr/$device" \
        "$DOTS_DIR/waybar/$device" \
        "$LOG_DIR" || error "Failed to create directories"

    LOG_FILE="$LOG_DIR/backup-$(date +%Y%m%d-%H%M%S).log"
    log "Directories initialized for device: $device"
}

sync_file() {
    local source="$1"
    local target="$2"
    local display_name="${3:-$(basename "$source")}"

    if [[ ! -e "$source" ]]; then
        warn "Skipping $display_name - source does not exist: $source"
        return 1
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    log "Syncing $display_name"

    local rsync_output
    if [[ -d "$source" ]]; then
        # For directories, sync contents
        if rsync_output=$(rsync -r -l -v -h --progress --delete "$source/" "$target/" 2>&1); then
            echo "$rsync_output" | tee -a "$LOG_FILE"
            success "✓ Synced $display_name"
            return 0
        fi
    else
        # For files, sync directly
        if rsync_output=$(rsync -l -v -h --progress "$source" "$target" 2>&1); then
            echo "$rsync_output" | tee -a "$LOG_FILE"
            success "✓ Synced $display_name"
            return 0
        fi
    fi

    echo "$rsync_output" | tee -a "$LOG_FILE"
    warn "Failed to sync $display_name"
    return 1
}

sync_hypr() {
    local device="$1"
    local sync_count=0 fail_count=0

    log "=== Syncing Hypr Configs ==="

    # Sync shared hypr configs (from hyprland/ subdirectory in ~/.config/hypr/)
    log "Syncing shared hypr configs..."
    local -a shared_configs=(
        "animations.conf"
        "decor.conf"
        "keybinds.conf"
        "rules.conf"
    )

    for config in "${shared_configs[@]}"; do
        if sync_file "$HOME/.config/hypr/hyprland/$config" "$DOTS_DIR/hypr/shared/$config" "hypr/shared/$config"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    done

    # Sync device-specific hypr configs
    log "Syncing device-specific hypr configs..."
    local -a device_configs=(
        "autostart.conf"
        "device-keybinds.conf"
        "devices.conf"
        "env.conf"
        "workspaces.conf"
    )

    for config in "${device_configs[@]}"; do
        # These come from the device subdirectory in ~/.config/hypr/
        if sync_file "$HOME/.config/hypr/hyprland/$config" "$DOTS_DIR/hypr/$device/$config" "hypr/$device/$config"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    done

    # Sync root hypr files
    log "Syncing root hypr configs..."
    local -a root_configs=(
        "hyprland.conf"
        "hypridle.conf"
        "hyprlock.conf"
    )

    for config in "${root_configs[@]}"; do
        if sync_file "$HOME/.config/hypr/$config" "$DOTS_DIR/hypr/$config" "hypr/$config"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    done

    # Sync hypr scripts directory
    log "Syncing hypr scripts..."
    if sync_file "$HOME/.config/hypr/scripts" "$DOTS_DIR/hypr/scripts" "hypr/scripts"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    log "Hypr sync: $sync_count succeeded, $fail_count failed"
    return 0
}

sync_waybar() {
    local device="$1"
    local sync_count=0 fail_count=0

    log "=== Syncing Waybar Configs ==="

    # Sync device-specific waybar config
    log "Syncing device-specific waybar config..."
    if sync_file "$HOME/.config/waybar/config.jsonc" "$DOTS_DIR/waybar/$device/config.jsonc" "waybar/$device/config.jsonc"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    # Sync shared waybar style
    log "Syncing shared waybar style..."
    if sync_file "$HOME/.config/waybar/style.css" "$DOTS_DIR/waybar/style.css" "waybar/style.css"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    # Sync waybar scripts
    log "Syncing waybar scripts..."
    if sync_file "$HOME/.config/waybar/scripts" "$DOTS_DIR/waybar/scripts" "waybar/scripts"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    log "Waybar sync: $sync_count succeeded, $fail_count failed"
    return 0
}

sync_shared() {
    local sync_count=0 fail_count=0

    log "=== Syncing Shared Configs ==="

    local -a shared_dirs=(
        "kitty"
        "nvim"
        "rofi"
        "zsh"
        "fastfetch"
        "gtk-2.0"
        "gtk-3.0"
        "gtk-4.0"
    )

    for dir in "${shared_dirs[@]}"; do
        if sync_file "$HOME/.config/$dir" "$SHARED_DIR/$dir" "shared/$dir"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    done

    # Sync special files from home directory
    log "Syncing special dotfiles from home..."
    if sync_file "$HOME/.zshrc" "$SHARED_DIR/zshrc" "zshrc"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    if sync_file "$HOME/.p10k.zsh" "$SHARED_DIR/p10k.zsh" "p10k.zsh"; then
        ((sync_count++))
    else
        ((fail_count++))
    fi

    log "Shared sync: $sync_count succeeded, $fail_count failed"
    return 0
}

main() {
    log "=== Dotfiles Sync Started ==="

    check_dependencies

    local device
    device=$(detect_device)
    log "Detected device: $device"

    setup_directories "$device"

    # Sync everything
    sync_hypr "$device"
    sync_waybar "$device"
    sync_shared

    log "=== Sync Complete ==="
    success "Dotfiles sync completed successfully!"
    log "Log saved to: $LOG_FILE"
}

main "$@"
