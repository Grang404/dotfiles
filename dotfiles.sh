#!/bin/bash

set -o pipefail

# Configuration
readonly DOTFILES_ROOT="$HOME/dotfiles"
readonly SHARED_DIR="$DOTFILES_ROOT/dots/shared"
readonly PROFILE_DIR_BASE="$DOTFILES_ROOT/dots/profiles"
readonly LOG_DIR="$DOTFILES_ROOT/logs"

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Initialize log file (will be set after LOG_DIR is created)
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

detect_battery() {
    [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]
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
    local profile_dir="$1"
    mkdir -p "$SHARED_DIR" "$profile_dir" "$LOG_DIR" || error "Failed to create directories"

    # Set log file after directory is created
    LOG_FILE="$LOG_DIR/backup-$(date +%Y%m%d-%H%M%S).log"
    log "Directories initialized"
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -f, --full       Full sync (all dotfiles) [default for cron]
    -p, --profile    Profile-only sync (hypr + waybar)
    -h, --help       Show this help message

If run interactively without arguments, you'll be prompted to choose.
EOF
    exit 0
}

get_sync_mode() {
    if [[ ! -t 0 ]]; then
        RET_MODE="1"
        return
    fi

    echo "" >&2
    echo "Select sync mode:" >&2
    echo "  1) Full sync (all dotfiles)" >&2
    echo "  2) Profile-only (hypr + waybar)" >&2
    echo "  3) Exit" >&2
    echo "" >&2
    read -r -p "Enter your choice (default: 1): " choice

    if [[ "$choice" == "3" ]]; then
        echo "Exiting..." >&2
        exit 0
    fi

    RET_MODE="${choice:-1}"
}

sync_dotfile() {
    local source="$1"
    local target="$2"
    local name
    name="$(basename "$source")"

    if [[ ! -e "$source" ]]; then
        warn "Skipping $name - source does not exist: $source"
        return 1
    fi

    log "Syncing $name from $source to $target/"

    # Run rsync and capture output
    local rsync_output
    if rsync_output=$(rsync "${RSYNC_OPTS[@]}" "$source" "$target/" 2>&1); then
        echo "$rsync_output" | tee -a "$LOG_FILE"
        success "✓ Synced $name"
        return 0
    else
        echo "$rsync_output" | tee -a "$LOG_FILE"
        warn "Failed to sync $name"
        return 1
    fi
}

main() {
    local mode sync_count=0 fail_count=0 profile_dir

    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -f | --full)
            mode="1"
            shift
            ;;
        -p | --profile)
            mode="2"
            shift
            ;;
        -h | --help)
            usage
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
        esac
    done

    log "=== Dotfiles Backup Started ==="

    check_dependencies

    # Determine profile directory
    if detect_battery; then
        profile_dir="$PROFILE_DIR_BASE/laptop"
        log "Detected laptop profile"
    else
        profile_dir="$PROFILE_DIR_BASE/desktop"
        log "Detected desktop profile"
    fi

    setup_directories "$profile_dir"

    # Get sync mode (from args or prompt)
    if [[ -z "${mode:-}" ]]; then
        get_sync_mode
        mode="$RET_MODE"
    fi
    log "Sync mode: $([[ "$mode" == "1" ]] && echo "Full" || echo "Profile-only")"

    # Rsync options
    readonly RSYNC_OPTS=(
        -r -l -v -h
        --progress
        --delete-excluded
        --exclude='plugins/zsh-*'
        --exclude='themes/powerlevel10k'
        --exclude='.git'
        --exclude='*.swp'
        --exclude='*.bak'
    )

    # Profile-specific files (always sync)
    local -a profile_files=(
        "$HOME/.config/hypr"
        "$HOME/.config/waybar"
    )

    # Shared files (only in full sync)
    local -a shared_files=(
        "$HOME/.config/kitty"
        "$HOME/.config/nvim"
        "$HOME/.config/rofi"
        "$HOME/.config/zsh"
        "$HOME/.config/fastfetch"
        "$HOME/.config/gtk-2.0"
        "$HOME/.config/gtk-3.0"
        "$HOME/.config/gtk-4.0"
    )

    # Special files with custom names
    declare -A special_files=(
        ["$HOME/.zshrc"]="zshrc"
        ["$HOME/.p10k.zsh"]="p10k.zsh"
    )

    # Sync profile-specific files
    log "Syncing profile-specific files to $profile_dir..."
    for dotfile in "${profile_files[@]}"; do
        log "Attempting to sync: $dotfile"
        if sync_dotfile "$dotfile" "$profile_dir"; then
            ((sync_count++))
        else
            ((fail_count++))
        fi
    done

    log "Profile sync complete. Mode is: $mode"

    # Sync shared files (full sync only)
    if [[ "$mode" == "1" ]]; then
        log "Syncing shared files to $SHARED_DIR..."
        for dotfile in "${shared_files[@]}"; do
            log "Attempting to sync: $dotfile"
            if sync_dotfile "$dotfile" "$SHARED_DIR"; then
                ((sync_count++))
            else
                ((fail_count++))
            fi
        done

        # Sync special files
        log "Syncing special files to $SHARED_DIR..."
        for source in "${!special_files[@]}"; do
            local dest_name="${special_files[$source]}"
            log "Attempting to sync special file: $source -> $dest_name"
            if [[ -e "$source" ]]; then
                log "Syncing $(basename "$source") as $dest_name"
                local rsync_output
                if rsync_output=$(rsync -l -v -h --progress "$source" "$SHARED_DIR/$dest_name" 2>&1); then
                    echo "$rsync_output" | tee -a "$LOG_FILE"
                    success "✓ Synced $dest_name"
                    ((sync_count++))
                else
                    echo "$rsync_output" | tee -a "$LOG_FILE"
                    warn "Failed to sync $dest_name"
                    ((fail_count++))
                fi
            else
                warn "Skipping $dest_name - source does not exist: $source"
                ((fail_count++))
            fi
        done
    fi

    # Summary
    log "=== Backup Complete ==="
    log "Successfully synced: $sync_count files"
    [[ $fail_count -gt 0 ]] && warn "Failed/Skipped: $fail_count files"
    success "Dotfiles backup completed successfully!"
    log "Log saved to: $LOG_FILE"
}

main "$@"
