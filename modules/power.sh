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

# 3. Cinnamon Desktop Power & Battery Preferences
setup_cinnamon_power() {
    if ! command -v gsettings >/dev/null 2>&1; then
        return 0
    fi

    log_info "Configuring Cinnamon power and battery settings..."
    local schema="org.cinnamon.settings-daemon.plugins.power"

    # Screen off inactivity: 3 hours on AC (10800s), 1 hour on Battery (3600s)
    gsettings set "$schema" sleep-display-ac 10800 2>/dev/null || true
    gsettings set "$schema" sleep-display-battery 3600 2>/dev/null || true

    # Suspend when inactive: Never (0)
    gsettings set "$schema" sleep-inactive-ac-timeout 0 2>/dev/null || true
    gsettings set "$schema" sleep-inactive-battery-timeout 0 2>/dev/null || true

    # Lid close: Do nothing (keep running)
    gsettings set "$schema" lid-close-ac-action 'nothing' 2>/dev/null || true
    gsettings set "$schema" lid-close-battery-action 'nothing' 2>/dev/null || true
    gsettings set "$schema" lid-close-suspend-with-external-monitor false 2>/dev/null || true

    # Power button: Ask (interactive)
    gsettings set "$schema" button-power 'interactive' 2>/dev/null || true

    # On battery, dim screen when inactive: true, level: 10%, after 10 minutes (600s)
    gsettings set "$schema" idle-dim-battery true 2>/dev/null || true
    gsettings set "$schema" idle-brightness 10 2>/dev/null || true
    gsettings set "$schema" idle-dim-time 600 2>/dev/null || true

    log_ok "Cinnamon power preferences configured."
}

# 4. Permanently Disable Bluetooth at Boot/Bootstrap
disable_bluetooth() {
    log_info "Permanently disabling Bluetooth service and kernel radio at boot..."
    # Stop and mask the systemd service so it cannot be socket-activated or started at boot
    run_sudo systemctl stop bluetooth 2>/dev/null || true
    run_sudo systemctl mask bluetooth 2>/dev/null || true

    # Blacklist bluetooth drivers from auto-loading at boot
    local bl_conf="/etc/modprobe.d/blacklist-bluetooth.conf"
    local bl_rules="blacklist btusb
blacklist bluetooth
blacklist btrtl
blacklist btintel
blacklist btbcm
"
    if [ ! -f "$bl_conf" ] || [ "$(cat "$bl_conf" 2>/dev/null)" != "$bl_rules" ]; then
        echo "$bl_rules" | run_sudo tee "$bl_conf" >/dev/null
        log_ok "Blacklisted Bluetooth kernel modules in $bl_conf."
    fi

    # Hardware RFKill block on bluetooth
    if command -v rfkill >/dev/null 2>&1; then
        run_sudo rfkill block bluetooth 2>/dev/null || true
    fi
    log_ok "Bluetooth permanently disabled at boot."
}

# 5. Keyboard Backlight (100% at Boot & Turn Off on Lid Close)
setup_keyboard_backlight() {
    log_info "Configuring keyboard backlight (100% on boot, off on lid close)..."

    local helper_script="/usr/local/bin/kbd-backlight-lid"
    local service_file="/etc/systemd/system/kbd-backlight-lid.service"

    # Install helper daemon script
    local script_content='#!/usr/bin/env bash
# kbd-backlight-lid: Sets kbd backlight to 100% on boot and monitors lid close/open
set -euo pipefail

set_backlight() {
    local target="$1" # "max" or "0"
    for dev in /sys/class/leds/*kbd_backlight*; do
        [ -d "$dev" ] || continue
        if [ "$target" = "max" ]; then
            local max_val
            max_val="$(cat "$dev/max_brightness" 2>/dev/null || echo 2)"
            echo "$max_val" > "$dev/brightness" 2>/dev/null || true
        else
            echo "0" > "$dev/brightness" 2>/dev/null || true
        fi
    done
}

# Set 100% at boot/service startup
set_backlight "max"

# Monitor lid state transitions via acpi events or input device
last_state="open"
while true; do
    curr_state="open"
    for state_file in /proc/acpi/button/lid/*/state; do
        if [ -f "$state_file" ] && grep -qi "closed" "$state_file"; then
            curr_state="closed"
            break
        fi
    done

    if [ "$curr_state" != "$last_state" ]; then
        if [ "$curr_state" = "closed" ]; then
            set_backlight "0"
        else
            set_backlight "max"
        fi
        last_state="$curr_state"
    fi
    sleep 1
done
'

    echo "$script_content" | run_sudo tee "$helper_script" >/dev/null
    run_sudo chmod +x "$helper_script"

    local service_content="[Unit]
Description=Keyboard Backlight 100% on boot & Lid Control
After=systemd-udevd.service sys-subsystem-net-devices.target

[Service]
Type=simple
ExecStart=$helper_script
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
"

    echo "$service_content" | run_sudo tee "$service_file" >/dev/null
    run_sudo systemctl daemon-reload
    run_sudo systemctl enable --now kbd-backlight-lid.service
    log_ok "Keyboard backlight service installed and active."
}

main() {
    log_info "--- Running Module: power ---"
    setup_lid_switch
    setup_tlp
    setup_cinnamon_power
    disable_bluetooth
    setup_keyboard_backlight
    log_ok "Power configuration module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

