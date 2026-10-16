#!/usr/bin/env bash
# mom/cockpit.sh - Emergency Action & Triage Cockpit
# Spawns isolated tmux triage session with agy + root shell, registers remote control, launches Firefox
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

# 2. Spin up dedicated tmux session: Left pane agy, Right pane diagnostic bash
if command -v tmux >/dev/null 2>&1; then
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        # Create session with agy in pane 1
        tmux new-session -d -s "$SESSION_NAME" -n "triage" "agy"
        # Split window horizontally: diagnostic bash shell
        tmux split-window -h -t "$SESSION_NAME:1" "bash"
        log_alert "Created tmux triage cockpit: [$SESSION_NAME]"
    else
        log_alert "Tmux session [$SESSION_NAME] already running."
    fi
fi

# 3. GUI Apps if in active desktop session (DISPLAY or WAYLAND_DISPLAY)
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    # Spawn Firefox in background if not already running
    if ! pgrep -x "firefox" >/dev/null 2>&1 && command -v firefox >/dev/null 2>&1; then
        log_alert "Launching Firefox in triage environment..."
        nohup firefox >/dev/null 2>&1 &
    fi

    # Spawn Antigravity GUI if available
    if command -v antigravity >/dev/null 2>&1 && ! pgrep -x "antigravity" >/dev/null 2>&1; then
        nohup antigravity >/dev/null 2>&1 &
        log_alert "Antigravity GUI focused."
    fi
fi

log_alert "Cockpit ready. Connect via: tmux attach -t mom-triage (or via agy remote-control on phone)."
