#!/usr/bin/env bash
# mom/cockpit.sh - Emergency Action & Triage Cockpit
# Spawns multi-pane triage cockpit (agy, Neovim/editor, bash shell), remote control, and browsers
set -euo pipefail

log_alert() { echo -e "\033[1;32m[MOM:COCKPIT]\033[0m $*"; }

log_alert "Spawning triage cockpit..."

SESSION_NAME="mom-triage"

# 1. Start or prepare agy remote-control daemon for phone access
if command -v agy >/dev/null 2>&1; then
    local_host="$(hostname 2>/dev/null || echo "node")"
    log_alert "Activating AGY Remote Control for phone connection..."
    agy remote-control start --name "mom-${local_host}" 2>/dev/null || true
fi

# Helper to read values from settings.json
SETTINGS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/settings.json"
get_setting() {
    local query="$1"
    local default="$2"
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        local val
        val="$(jq -r "$query // empty" "$SETTINGS_FILE" 2>/dev/null || true)"
        echo "${val:-$default}"
    else
        echo "$default"
    fi
}

# 2. Spin up dedicated multi-pane tmux triage cockpit:
# ----------------------------------------------------
# |                |             Editor              |
# |    AGY CLI     |---------------------------------|
# |  (Left Half)   |          Bash Shell             |
# |                |          (Diagnostic)           |
# ----------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        # Left pane: agy
        tmux new-session -d -s "$SESSION_NAME" -n "cockpit" "agy"

        # Split right half: configured editor
        configured_editor="$(get_setting ".tools.primary_cli_editor" "nvim")"
        if ! command -v "$configured_editor" >/dev/null 2>&1; then
            configured_editor="nano"
        fi
        tmux split-window -h -t "$SESSION_NAME:1" "$configured_editor"

        # Split bottom-right: active bash shell for diagnostics
        tmux split-window -v -t "$SESSION_NAME:1.2" "bash"

        # Select the left AGY pane as active
        tmux select-pane -t "$SESSION_NAME:1.1"

        log_alert "Cockpit layout ready: Pane 1: agy | Pane 2: $configured_editor | Pane 3: bash"
    else
        log_alert "Tmux session [$SESSION_NAME] already running."
    fi
fi

# 3. GUI Apps if in active desktop session (preserve Chrome, Firefox, and Antigravity GUI)
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    primary_browser="$(get_setting ".tools.primary_browser" "firefox")"
    if ! pgrep -x "$primary_browser" >/dev/null 2>&1 && command -v "$primary_browser" >/dev/null 2>&1; then
        log_alert "Launching $primary_browser..."
        nohup "$primary_browser" >/dev/null 2>&1 &
    fi

    # Spawn Antigravity GUI if installed
    if command -v antigravity >/dev/null 2>&1 && ! pgrep -x "antigravity" >/dev/null 2>&1; then
        nohup antigravity >/dev/null 2>&1 &
        log_alert "Antigravity GUI focused."
    fi
fi

log_alert "Cockpit ready. Connect via: tmux attach -t mom-triage"
