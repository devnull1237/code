#!/usr/bin/env bash
# modules/02-security.sh - SSH server, UFW firewall, and Git/SSH key management
set -euo pipefail

log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# 1. OpenSSH Server Configuration
setup_sshd() {
    log_info "Configuring OpenSSH server..."
    if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
        log_info "Enabling and starting SSH service..."
        run_sudo systemctl enable --now ssh || run_sudo systemctl enable --now sshd
        log_ok "SSH service started and enabled on boot."
    else
        log_ok "SSH service is already running."
    fi
}

# 2. UFW Firewall Setup (Safe defaults)
setup_firewall() {
    log_info "Checking UFW firewall configuration..."
    if ! command -v ufw >/dev/null 2>&1; then
        log_warn "UFW is not installed. Skipping firewall setup."
        return 0
    fi

    # Allow SSH port before enabling to prevent accidental lockout
    run_sudo ufw default deny incoming >/dev/null 2>&1 || true
    run_sudo ufw default allow outgoing >/dev/null 2>&1 || true
    run_sudo ufw allow ssh >/dev/null 2>&1 || true

    local ufw_status
    ufw_status="$(run_sudo ufw status | head -n1 || true)"
    if [[ "$ufw_status" != *"active"* ]]; then
        log_info "Enabling UFW..."
        echo "y" | run_sudo ufw enable >/dev/null 2>&1 || true
        log_ok "UFW enabled with default deny incoming and SSH allowed."
    else
        log_ok "UFW is already active."
    fi
}

# 3. SSH Key Generation for GitHub
setup_ssh_key() {
    log_info "Checking personal SSH key..."
    local key_file="$HOME/.ssh/id_ed25519"
    local git_email="thekylecarlson@gmail.com"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [ ! -f "$key_file" ]; then
        log_info "Generating new ed25519 SSH key ($git_email)..."
        ssh-keygen -t ed25519 -C "$git_email" -f "$key_file" -N ""
        chmod 600 "$key_file"
        chmod 644 "${key_file}.pub"
        log_ok "Generated $key_file"
        log_info "Your public SSH key for GitHub is:"
        echo -e "\033[1;36m$(cat "${key_file}.pub")\033[0m"
    else
        log_ok "SSH key already exists: $key_file"
    fi
}

# 4. Git Identity Configuration
setup_git_config() {
    log_info "Configuring Git author identity..."
    local git_user="Kyle Carlson"
    local git_email="thekylecarlson@gmail.com"

    git config --global user.name "$git_user"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor nvim
    git config --global pull.rebase false
    log_ok "Git global config set (User: $git_user, Email: $git_email, Editor: nvim)."
}

main() {
    log_info "--- Running Module: 02-security ---"
    setup_sshd
    setup_firewall
    setup_ssh_key
    setup_git_config
    log_ok "Security and identity module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
