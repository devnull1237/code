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

        # Split right half: editor (nvim if available, fallback vim or nano)
        local_editor="nano"
        if command -v nvim >/dev/null 2>&1; then
            local_editor="nvim"
        elif command -v vim >/dev/null 2>&1; then
            local_editor="vim"
        fi
        tmux split-window -h -t "$SESSION_NAME:1" "$local_editor"

        # Split bottom-right: active bash shell for diagnostics
        tmux split-window -v -t "$SESSION_NAME:1.2" "bash"

        # Select the left AGY pane as active
        tmux select-pane -t "$SESSION_NAME:1.1"

        log_alert "Cockpit layout ready: Pane 1: agy | Pane 2: $local_editor | Pane 3: bash"
    else
        log_alert "Tmux session [$SESSION_NAME] already running."
    fi
fi

# 3. GUI Apps if in active desktop session (preserve Chrome, Firefox, and Antigravity GUI)
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    # Spawn Firefox if available
    if ! pgrep -x "firefox" >/dev/null 2>&1 && command -v firefox >/dev/null 2>&1; then
        log_alert "Launching Firefox..."
        nohup firefox >/dev/null 2>&1 &
    fi

    # Spawn Antigravity GUI if installed
    if command -v antigravity >/dev/null 2>&1 && ! pgrep -x "antigravity" >/dev/null 2>&1; then
        nohup antigravity >/dev/null 2>&1 &
        log_alert "Antigravity GUI focused."
    fi
fi

log_alert "Cockpit ready. Connect via: tmux attach -t mom-triage"
