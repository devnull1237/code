#!/usr/bin/env bash
# modules/packages.sh - Core CLI tools, development utilities, monitoring, and browsers
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

# 1. Core CLI, System & Monitoring Utilities
install_core_packages() {
    log_info "Checking core system, terminal, and monitoring packages..."
    local pkgs=(
        bash
        bash-completion
        tmux
        xclip
        neovim
        git
        curl
        wget
        htop
        btop
        powertop
        jq
        tree
        upower
        openssh-server
        ufw
    )

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_info "Installing missing packages: ${missing[*]}"
        run_sudo apt-get update -qq
        run_sudo apt-get install -y "${missing[@]}"
        log_ok "Core & monitoring packages installed."
    else
        log_ok "All core & monitoring packages are already installed."
    fi
}

# 2. Google Chrome (Official Google Apt Repository)
install_google_chrome() {
    if command -v google-chrome >/dev/null 2>&1 || dpkg -s google-chrome-stable >/dev/null 2>&1; then
        log_ok "Google Chrome is already installed."
        return 0
    fi

    log_info "Setting up Google Chrome repository and installing..."
    local keyring="/etc/apt/keyrings/google-chrome.gpg"
    local list_file="/etc/apt/sources.list.d/google-chrome.list"

    run_sudo mkdir -p /etc/apt/keyrings
    if [ ! -f "$keyring" ]; then
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | run_sudo tee "$keyring" >/dev/null
    fi

    if [ ! -f "$list_file" ]; then
        echo "deb [arch=amd64 signed-by=$keyring] http://dl.google.com/linux/chrome/deb/ stable main" | run_sudo tee "$list_file" >/dev/null
    fi

    run_sudo apt-get update -qq
    run_sudo apt-get install -y google-chrome-stable
    log_ok "Google Chrome installed successfully."
}

# 3. Firefox (Standard on Linux Mint)
install_firefox() {
    if command -v firefox >/dev/null 2>&1; then
        log_ok "Firefox is already installed."
    else
        log_info "Installing Firefox..."
        run_sudo apt-get install -y firefox
        log_ok "Firefox installed."
    fi
}

# 4. Tor Browser (Standard apt torbrowser-launcher)
install_tor_browser() {
    if dpkg -s torbrowser-launcher >/dev/null 2>&1; then
        log_ok "Tor Browser Launcher is already installed."
    else
        log_info "Installing Tor Browser Launcher..."
        run_sudo apt-get install -y torbrowser-launcher
        log_ok "Tor Browser Launcher installed."
    fi
}

# 5. Mullvad VPN (Official Mullvad Apt Repository)
install_mullvad() {
    if command -v mullvad >/dev/null 2>&1 || dpkg -s mullvad-vpn >/dev/null 2>&1; then
        log_ok "Mullvad VPN is already installed."
        return 0
    fi

    log_info "Configuring Mullvad VPN repository..."
    local keyring="/etc/apt/keyrings/mullvad-keyring.asc"
    local list_file="/etc/apt/sources.list.d/mullvad.list"

    run_sudo mkdir -p /etc/apt/keyrings
    if [ ! -f "$keyring" ]; then
        curl -fsSLo "$keyring" https://repository.mullvad.net/deb/mullvad-keyring.asc
    fi

    if [ ! -f "$list_file" ]; then
        echo "deb [signed-by=$keyring arch=amd64] https://repository.mullvad.net/deb/stable stable main" | run_sudo tee "$list_file" >/dev/null
    fi

    run_sudo apt-get update -qq
    run_sudo apt-get install -y mullvad-vpn
    log_ok "Mullvad VPN installed successfully."
}

main() {
    log_info "--- Running Module: packages ---"
    install_core_packages
    install_firefox
    install_google_chrome
    install_tor_browser
    install_mullvad
    log_ok "Package module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
