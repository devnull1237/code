#!/usr/bin/env bash
# modules/power.sh - Laptop power management, TLP, clocks, and lid behavior
# Lowers wakeups, optimizes C-states/governors, turns off screen on lid close
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

# 1. Systemd logind lid switch configuration
setup_lid_switch() {
    log_info "Configuring lid switch handling (turn off screen, do not suspend)..."
    local logind_conf_dir="/etc/systemd/logind.conf.d"
    local lid_file="$logind_conf_dir/10-lid-handling.conf"

    run_sudo mkdir -p "$logind_conf_dir"

    # HandleLidSwitch=lock: Locks session and turns off display without putting system to sleep
    # HandleLidSwitchExternalPower=ignore: Does nothing / keeps running when plugged into AC
    local desired_content="[Login]
HandleLidSwitch=lock
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
"

    if [ ! -f "$lid_file" ] || [ "$(cat "$lid_file" 2>/dev/null)" != "$desired_content" ]; then
        echo "$desired_content" | run_sudo tee "$lid_file" >/dev/null
        log_ok "Wrote $lid_file."
        if systemctl is-active --quiet systemd-logind; then
            run_sudo systemctl restart systemd-logind || true
            log_ok "systemd-logind reloaded."
        fi
    else
        log_ok "Lid switch configuration is already up to date."
    fi
}

# 2. TLP Installation & Battery/Clock Governor Management
setup_tlp() {
    log_info "Configuring TLP for aggressive laptop power management..."

    # If power-profiles-daemon is installed, mask/disable it to prevent governor conflicts
    if systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then
        log_info "Disabling conflicting power-profiles-daemon in favor of TLP..."
        run_sudo systemctl stop power-profiles-daemon || true
        run_sudo systemctl mask power-profiles-daemon || true
    fi

    local pkgs=(tlp tlp-rdw)
    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_info "Installing missing TLP packages: ${missing[*]}"
        run_sudo apt-get update -qq
        run_sudo apt-get install -y "${missing[@]}"
    fi

    # Ensure TLP service is enabled and started
    if ! systemctl is-active --quiet tlp; then
        log_info "Starting TLP service..."
        run_sudo systemctl enable --now tlp
        log_ok "TLP service active."
    else
        log_ok "TLP service is already running."
    fi
}

main() {
    log_info "--- Running Module: power ---"
    setup_lid_switch
    setup_tlp
    log_ok "Power configuration module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
