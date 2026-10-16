#!/usr/bin/env bash
# modules/hydrate/radios.sh - Hydrate RF, Bluetooth, and Wi-Fi
set -euo pipefail

run_sudo() { [ "$(id -u)" -eq 0 ] && "$@" || sudo "$@"; }

apply_radios() {
    local json="$1"
    local rfkill_target bt_target wifi_target

    rfkill_target="$(jq -r '.radios.rfkill // empty' "$json")"
    bt_target="$(jq -r '.radios.bluetooth // empty' "$json")"
    wifi_target="$(jq -r '.radios.wifi // empty' "$json")"

    # 1. RFKill
    if [ "$rfkill_target" = "block" ]; then
        echo -e "\033[1;33m[HYDRATE:RADIO]\033[0m Blocking all RF devices..."
        run_sudo rfkill block all 2>/dev/null || true
    elif [ "$rfkill_target" = "unblock" ]; then
        echo -e "\033[1;32m[HYDRATE:RADIO]\033[0m Unblocking RF devices..."
        run_sudo rfkill unblock all 2>/dev/null || true
    fi

    # 2. Bluetooth
    if [ "$bt_target" = "masked" ] || [ "$bt_target" = "off" ]; then
        echo -e "\033[1;33m[HYDRATE:RADIO]\033[0m Disabling Bluetooth..."
        run_sudo systemctl stop bluetooth 2>/dev/null || true
        run_sudo systemctl mask bluetooth 2>/dev/null || true
    elif [ "$bt_target" = "active" ] || [ "$bt_target" = "on" ]; then
        echo -e "\033[1;32m[HYDRATE:RADIO]\033[0m Enabling Bluetooth..."
        run_sudo systemctl unmask bluetooth 2>/dev/null || true
        run_sudo systemctl start bluetooth 2>/dev/null || true
    fi

    # 3. Wi-Fi Interfaces
    if [ "$wifi_target" = "down" ]; then
        for iface in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^wl|^wifi'); do
            run_sudo ip link set "$iface" down 2>/dev/null || true
        done
        echo -e "\033[1;33m[HYDRATE:RADIO]\033[0m Wi-Fi interfaces taken down."
    elif [ "$wifi_target" = "up" ] || [ "$wifi_target" = "active" ]; then
        for iface in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^wl|^wifi'); do
            run_sudo ip link set "$iface" up 2>/dev/null || true
        done
        echo -e "\033[1;32m[HYDRATE:RADIO]\033[0m Wi-Fi interfaces brought up."
    fi
}

[ -n "${1:-}" ] && [ -f "$1" ] && apply_radios "$1"
