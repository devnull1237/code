#!/usr/bin/env bash
# bootstrap.sh - Zero-to-running machine spin-up script
# Idempotent provisioning for Debian/Ubuntu/Mint systems

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

link_file() {
    local src="$1"
    local dst="$2"

    if [ -L "$dst" ]; then
        local current_raw current_target src_target
        current_raw="$(readlink "$dst" || true)"
        current_target="$(readlink -f "$dst" || true)"
        src_target="$(readlink -f "$src" || true)"

        if [ "$current_raw" = "$src" ] || { [ -n "$current_target" ] && [ "$current_target" = "$src_target" ]; }; then
            ok "Symlink already in place: $dst -> $src"
            return 0
        fi
        warn "Updating existing symlink: $dst"
        rm -f "$dst"
    elif [ -e "$dst" ]; then
        warn "Existing file found at $dst. Backing up to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    ok "Linked $dst -> $src"
}

# 1. Package Installation
install_packages() {
    info "Checking required system packages..."
    local pkgs=(
        bash
        bash-completion
        git
        curl
        wget
        vim
        neovim
        htop
        tmux
        jq
        tree
        upower
    )

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        info "Installing missing packages: ${missing[*]}"
        local SUDO_CMD=""
        if [ "$(id -u)" -ne 0 ]; then
            if command -v sudo >/dev/null 2>&1; then
                SUDO_CMD="sudo"
            else
                warn "Root privileges needed to install packages. Please run as root or install sudo."
                return 1
            fi
        fi
        $SUDO_CMD apt-get update -qq
        $SUDO_CMD apt-get install -y "${missing[@]}"
    else
        ok "All core packages already installed."
    fi
}

# 2. Directory structure
setup_directories() {
    info "Setting up standard directories..."
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.config"
    [ -e "$HOME/code" ] || mkdir -p "$HOME/code"
    mkdir -p "$HOME/Code"
    ok "Directories ready."
}

# 3. Dotfile Symlinks
setup_symlinks() {
    info "Configuring symlinks..."
    local base_src="$DOTFILES_DIR"
    if [ -d "$HOME/code" ] && [ "$(readlink -f "$HOME/code")" = "$(readlink -f "$DOTFILES_DIR")" ]; then
        base_src="$HOME/code"
    fi
    link_file "$base_src/.bashrc" "$HOME/.bashrc"
    link_file "$base_src/.bash_aliases" "$HOME/.bash_aliases"
    link_file "$base_src/.inputrc" "$HOME/.inputrc"
}

# 4. Default Shell Check
setup_shell() {
    local bash_path
    bash_path="$(command -v bash || true)"
    local current_shell_real="$(readlink -f "$SHELL" 2>/dev/null || true)"
    local bash_real="$(readlink -f "$bash_path" 2>/dev/null || true)"

    if [ -n "$bash_real" ] && [ "$current_shell_real" != "$bash_real" ]; then
        info "Default shell is currently $SHELL."
        info "To set Bash as your default shell, run: chsh -s $bash_path"
    else
        ok "Bash is already your active shell."
    fi
}

main() {
    local dotfiles_only=false
    for arg in "$@"; do
        case "$arg" in
            --dotfiles-only|-d) dotfiles_only=true ;;
        esac
    done

    info "Starting machine bootstrap from $DOTFILES_DIR"
    setup_directories
    if [ "$dotfiles_only" = true ]; then
        info "Skipping package installation (--dotfiles-only specified)."
    else
        install_packages
    fi
    setup_symlinks
    setup_shell
    ok "Bootstrap complete! You're ready to rock."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
