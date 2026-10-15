#!/usr/bin/env bash
# modules/04-dotfiles.sh - Idempotent symlink manager for shell and tool dotfiles
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

link_file() {
    local src="$1"
    local dst="$2"

    if [ -L "$dst" ]; then
        local current_raw current_target src_target
        current_raw="$(readlink "$dst" || true)"
        current_target="$(readlink -f "$dst" || true)"
        src_target="$(readlink -f "$src" || true)"

        if [ "$current_raw" = "$src" ] || { [ -n "$current_target" ] && [ "$current_target" = "$src_target" ]; }; then
            log_ok "Symlink already in place: $dst -> $src"
            return 0
        fi
        log_warn "Updating existing symlink: $dst"
        rm -f "$dst"
    elif [ -e "$dst" ]; then
        log_warn "Existing file found at $dst. Backing up to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    log_ok "Linked $dst -> $src"
}

setup_directories() {
    log_info "Ensuring user directory layout..."
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/code"
    mkdir -p "$HOME/Code"
    log_ok "Directories ready."
}

setup_symlinks() {
    log_info "Linking dotfiles from $DOTFILES_DIR..."
    local base_src="$DOTFILES_DIR"
    if [ -d "$HOME/code" ] && [ "$(readlink -f "$HOME/code")" = "$(readlink -f "$DOTFILES_DIR")" ]; then
        base_src="$HOME/code"
    fi

    link_file "$base_src/.bashrc" "$HOME/.bashrc"
    link_file "$base_src/.bash_aliases" "$HOME/.bash_aliases"
    link_file "$base_src/.inputrc" "$HOME/.inputrc"
    link_file "$base_src/.tmux.conf" "$HOME/.tmux.conf"
}

setup_default_shell() {
    local bash_path
    bash_path="$(command -v bash || true)"
    local current_shell_real="$(readlink -f "$SHELL" 2>/dev/null || true)"
    local bash_real="$(readlink -f "$bash_path" 2>/dev/null || true)"

    if [ -n "$bash_real" ] && [ "$current_shell_real" != "$bash_real" ]; then
        log_info "Default shell is currently $SHELL."
        log_info "Run this command to make Bash your default shell: chsh -s $bash_path"
    else
        log_ok "Bash is already your default shell."
    fi
}

main() {
    log_info "--- Running Module: 04-dotfiles ---"
    setup_directories
    setup_symlinks
    setup_default_shell
    log_ok "Dotfiles module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
