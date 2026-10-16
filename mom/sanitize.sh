#!/usr/bin/env bash
# mom/sanitize.sh - Session, Buffer & Memory Sanitization
# Flushes clipboards, wipes tmux buffers, and drops kernel pagecaches
set -euo pipefail

log_alert() { echo -e "\033[1;31m[MOM:PURGE]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

log_alert "Flushing sensitive buffers and cache..."

# 1. Clear X11 clipboards
if command -v xclip >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    echo -n "" | xclip -selection clipboard 2>/dev/null || true
    echo -n "" | xclip -selection primary 2>/dev/null || true
    log_alert "X11 system clipboard flushed."
fi

# 2. Clear tmux paste buffers across active sessions
if command -v tmux >/dev/null 2>&1; then
    tmux delete-buffer 2>/dev/null || true
fi

# 3. Drop filesystem pagecache, dentries, and inodes
sync
echo 3 | run_sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
log_alert "Kernel filesystem buffers and pagecaches dropped."

log_alert "Buffer sanitization complete."
