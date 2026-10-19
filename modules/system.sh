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

# 4. NVMe, Swappiness, and Inode Cache Tuning
configure_nvme_and_memory() {
    log_info "Tuning swappiness, inode cache, and NVMe endurance..."

    # Sysctl configuration
    local sysctl_file="/etc/sysctl.d/99-nerdbox-nvme.conf"
    local sysctl_rules="# Reduce swapping to preserve NVMe write endurance and prioritize DDR RAM
vm.swappiness = 10
# Preserve directory and inode structures in cache longer
vm.vfs_cache_pressure = 50
"

    if [ ! -f "$sysctl_file" ] || [ "$(cat "$sysctl_file" 2>/dev/null)" != "$sysctl_rules" ]; then
        echo "$sysctl_rules" | run_sudo tee "$sysctl_file" >/dev/null
        run_sudo sysctl --system >/dev/null 2>&1 || true
        log_ok "Applied sysctl memory & swappiness optimizations."
    else
        log_ok "Sysctl swappiness & NVMe tuning already in place."
    fi

    # Add noatime to root ext4 filesystem in /etc/fstab if not present
    if [ -f /etc/fstab ]; then
        if grep -E 'UUID=.*[[:space:]]+/[[:space:]]+ext4[[:space:]]+' /etc/fstab | grep -v -q 'noatime'; then
            log_info "Enabling noatime on root ext4 mount in /etc/fstab..."
            run_sudo sed -i -E 's|(UUID=[^[:space:]]+[[:space:]]+/[[:space:]]+ext4[[:space:]]+)(errors=remount-ro)|\1noatime,\2|' /etc/fstab
            run_sudo mount -o remount,noatime / 2>/dev/null || true
            log_ok "Root filesystem remounted with noatime."
        else
            log_ok "Root filesystem already configured with noatime."
        fi
    fi
}

main() {
    log_info "=== Initializing System & Package Manager ==="
    configure_apt_performance
    install_base_prereqs
    configure_nvme_and_memory
    upgrade_system
    log_ok "System initialization complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

