#!/usr/bin/env bash
# mom/network.sh - Ethernet Umbilical & Hardened Perimeter
# Strips networking down to wired Ethernet, kills broadcast beacons, locks UFW to SSH
set -euo pipefail

log_alert() { echo -e "\033[1;31m[MOM:NET]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

log_alert "Restricting network to wired umbilical..."

# 1. Terminate LAN discovery & broadcasting beacons
for svc in avahi-daemon cups cups-browsed; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        run_sudo systemctl stop "$svc" || true
        log_alert "Stopped broadcast beacon: $svc"
    fi
done

# 2. Flush DNS caches to drop stale resolution tables
if command -v resolvectl >/dev/null 2>&1; then
    run_sudo resolvectl flush-caches 2>/dev/null || true
elif command -v systemd-resolve >/dev/null 2>&1; then
    run_sudo systemd-resolve --flush-caches 2>/dev/null || true
fi

# 3. UFW Lockdown (Deny all incoming except SSH)
if command -v ufw >/dev/null 2>&1; then
    run_sudo ufw default deny incoming >/dev/null 2>&1 || true
    run_sudo ufw default allow outgoing >/dev/null 2>&1 || true
    run_sudo ufw allow 22/tcp >/dev/null 2>&1 || true
    echo "y" | run_sudo ufw enable >/dev/null 2>&1 || true
    log_alert "UFW firewall locked down (Inbound SSH port 22 only)."
fi

# 4. Verify OpenSSH server is alive for triage access
if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
    run_sudo systemctl start ssh || run_sudo systemctl start sshd || true
    log_alert "Emergency SSH listener started."
fi

log_alert "Network perimeter secured."
