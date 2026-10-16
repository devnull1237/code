#!/usr/bin/env bash
# mom/apps.sh - Terminate Distractions & Non-Essential Apps
# Kills game launchers, sync clients, chat apps, and disconnects VPNs
set -euo pipefail

log_alert() { echo -e "\033[1;31m[MOM:APPS]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Helper to read arrays from settings.json
SETTINGS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/settings.json"

get_json_array() {
    local path="$1"
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        jq -r "$path[]?" "$SETTINGS_FILE" 2>/dev/null || true
    fi
}

log_alert "Terminating non-essential user-space applications..."

# 1. Kill game launchers & background gaming clients
mapfile -t gaming_targets < <(get_json_array ".mom.kill_launchers")
if [ ${#gaming_targets[@]} -eq 0 ]; then
    gaming_targets=(steam steamwebhelper lutris heroic epicgameslauncher battlenet origin eadesktop wine wineserver)
fi

for app in "${gaming_targets[@]}"; do
    [ -z "$app" ] && continue
    if pgrep -fi "$app" >/dev/null 2>&1; then
        pkill -fi -9 "$app" 2>/dev/null || true
        log_alert "Terminated gaming client: $app"
    fi
done

# 2. Terminate background chat, media, & torrent clients
mapfile -t distraction_targets < <(get_json_array ".mom.kill_distractions")
if [ ${#distraction_targets[@]} -eq 0 ]; then
    distraction_targets=(discord spotify telegram-desktop slack element transmission-gtk qbittorrent deluge)
fi

for app in "${distraction_targets[@]}"; do
    [ -z "$app" ] && continue
    if pgrep -fi "$app" >/dev/null 2>&1; then
        pkill -fi -9 "$app" 2>/dev/null || true
        log_alert "Terminated background app: $app"
    fi
done

# 3. Disconnect and stop VPNs to simplify routing & eliminate network lockups
if command -v mullvad >/dev/null 2>&1; then
    mullvad disconnect 2>/dev/null || true
    log_alert "Mullvad VPN disconnected."
fi

for vpn_svc in openvpn wireguard-quick tailscale; do
    if systemctl is-active --quiet "$vpn_svc" 2>/dev/null; then
        run_sudo systemctl stop "$vpn_svc" || true
        log_alert "Stopped VPN service: $vpn_svc"
    fi
done

log_alert "Non-essential applications terminated."
