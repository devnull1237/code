#!/usr/bin/env bash
# mom/radios.sh - Total RF & Wireless Blackout
# Instantly terminates Wi-Fi, Bluetooth, NFC, and wireless modems
set -euo pipefail

log_alert() { echo -e "\033[1;31m[MOM:RADIO]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

log_alert "Engaging RF blackout..."

# 1. Hardware & Software RFKill
if command -v rfkill >/dev/null 2>&1; then
    run_sudo rfkill block all || true
    log_alert "All RF radios blocked via rfkill."
fi

# 2. Bluetooth Termination
if systemctl is-active --quiet bluetooth 2>/dev/null; then
    run_sudo systemctl stop bluetooth || true
    run_sudo systemctl mask bluetooth || true
    log_alert "Bluetooth service stopped and masked."
fi

# 3. Unload Bluetooth kernel modules
for mod in btusb btrtl btintel btbcm bluetooth; do
    if lsmod | grep -q "^$mod\b"; then
        run_sudo modprobe -r "$mod" 2>/dev/null || true
    fi
done

# 4. Bring down all wireless network interfaces
if command -v ip >/dev/null 2>&1; then
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -E '^wl|^wifi'); do
        log_alert "Taking down wireless interface: $iface"
        run_sudo ip link set "$iface" down 2>/dev/null || true
    done
fi

log_alert "Radio blackout complete."
