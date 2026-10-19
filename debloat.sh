#!/usr/bin/env bash
# debloat.sh - Purge Mint/Cinnamon bloatware & unnecessary services
# Zero questions. Enter sudo once, step away for ~2 min.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$SCRIPT_DIR/settings.json"

log_info() { echo -e "\033[1;34m[DEBLOAT]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# 1. Require sudo immediately & maintain keepalive
log_info "Initializing debloat sequence for Linux Mint Cinnamon..."
run_sudo -v
while true; do run_sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
KEEPALIVE_PID=$!
trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT

start_time="$(date +%s)"
export DEBIAN_FRONTEND=noninteractive

# 2. Gather debloat target list
targets=()
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
    while IFS= read -r pkg; do
        [ -n "$pkg" ] && targets+=("$pkg")
    done < <(jq -r '.packages.debloat[]? // empty' "$SETTINGS_FILE" 2>/dev/null || true)
fi

# Fallback baseline targets if settings.json is missing or unreadable
if [ ${#targets[@]} -eq 0 ]; then
    targets=(
        libreoffice-core libreoffice-common libreoffice-writer libreoffice-calc
        libreoffice-impress libreoffice-draw libreoffice-math libreoffice-base
        thunderbird hexchat rhythmbox celluloid hypnotix drawing simple-scan
        warpinator thingy sticky pix pix-data gnome-mines gnome-sudoku
        speech-dispatcher cups-browsed bluez bluez-obexd blueman bluetooth
    )
fi

# 3. Detect installed packages from target list
to_purge=()
for pkg in "${targets[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        to_purge+=("$pkg")
    fi
done

if [ ${#to_purge[@]} -gt 0 ]; then
    log_info "Purging ${#to_purge[@]} bloat packages: ${to_purge[*]}"
    run_sudo apt-get purge --auto-remove -y "${to_purge[@]}"
    log_ok "Bloat packages successfully purged."
else
    log_ok "No bloat packages found on system."
fi

# 4. Clean orphan configuration files & package cache
log_info "Purging orphaned packages, lingering config residues, and APT cache..."
run_sudo apt-get autoremove --purge -y -qq
run_sudo apt-get clean -qq

# 5. Mask unwanted background services & telemetry (system-wide)
log_info "Silencing telemetry and unnecessary system background daemons..."
unwanted_services=(
    whoopsie.service
    apport.service
    kerneloops.service
    avahi-daemon.service
    cups.service
    cups-browsed.service
    ModemManager.service
    bolt.service
    colord.service
)

for svc in "${unwanted_services[@]}"; do
    if systemctl list-unit-files "$svc" 2>/dev/null | grep -q "$svc"; then
        run_sudo systemctl stop "$svc" 2>/dev/null || true
        run_sudo systemctl disable "$svc" 2>/dev/null || true
        run_sudo systemctl mask "$svc" 2>/dev/null || true
    fi
done

# 6. Mask unwanted user session services (GNOME/Evolution background engines & speech)
log_info "Silencing background user session daemons (Evolution data servers, speech)..."
user_unwanted_services=(
    evolution-source-registry.service
    evolution-calendar-factory.service
    evolution-addressbook-factory.service
    speech-dispatcher.service
    obex.service
)

for usvc in "${user_unwanted_services[@]}"; do
    systemctl --user stop "$usvc" 2>/dev/null || true
    systemctl --user mask "$usvc" 2>/dev/null || true
done

end_time="$(date +%s)"
elapsed=$((end_time - start_time))

echo ""
log_ok "=================================================="
log_ok "Debloat complete in ${elapsed}s! System is clean and lean."
log_ok "=================================================="
