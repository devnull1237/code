#!/usr/bin/env bash
# modules/system.sh - Initial system upgrade, parallel downloads, and base prerequisites
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

# 1. Enable parallel downloads and fast mirrors in APT
configure_apt_performance() {
    log_info "Configuring APT for parallel downloads and retries..."
    local apt_conf="/etc/apt/apt.conf.d/99parallel-downloads"
    local config="Acquire::Queue-Mode "host";
Acquire::Retries "3";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
APT::Color "1";
"
    if [ ! -f "$apt_conf" ]; then
        echo "$config" | run_sudo tee "$apt_conf" >/dev/null
        log_ok "APT parallel connection tuning enabled."
    else
        log_ok "APT download tuning already in place."
    fi
}

# 2. Base prerequisites needed by all repositories and GPG keys
install_base_prereqs() {
    log_info "Installing base system prerequisites (ca-certificates, gpg, nala)..."
    local pkgs=(
        ca-certificates
        curl
        gnupg
        software-properties-common
        apt-transport-https
        nala
    )

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        run_sudo apt-get update -qq
        run_sudo apt-get install -y "${missing[@]}"
        log_ok "Base prerequisites and nala installed."
    else
        log_ok "Base prerequisites already present."
    fi
}

# 3. Full system update & upgrade
upgrade_system() {
    log_info "Running full system update & package upgrade..."
    export DEBIAN_FRONTEND=noninteractive
    
    # Remove any dead/stale 7.0 mongodb lists that block apt updates on noble
    run_sudo rm -f /etc/apt/sources.list.d/mongodb-org-7.0.list 2>/dev/null || true

    if command -v nala >/dev/null 2>&1; then
        run_sudo nala update
        run_sudo nala upgrade -y
    else
        run_sudo apt-get update -qq
        run_sudo apt-get dist-upgrade -y
    fi
    log_ok "System is up to date."
}

main() {
    log_info "=== Initializing System & Package Manager ==="
    configure_apt_performance
    install_base_prereqs
    upgrade_system
    log_ok "System initialization complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
