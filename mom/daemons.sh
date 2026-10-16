#!/usr/bin/env bash
# mom/daemons.sh - Service Attack Surface Reduction
# Shuts down database listeners and local AI endpoints while preserving SSH and core shell
set -euo pipefail

log_alert() { echo -e "\033[1;31m[MOM:DAEMON]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

log_alert "Terminating non-essential background service ports..."

# 1. Stop database daemons (MongoDB, Redis)
for db_svc in mongod redis-server redis; do
    if systemctl is-active --quiet "$db_svc" 2>/dev/null; then
        run_sudo systemctl stop "$db_svc" || true
        log_alert "Stopped database service: $db_svc"
    fi
done

# 2. Stop Ollama local model inference endpoint if running
if systemctl is-active --quiet ollama 2>/dev/null; then
    run_sudo systemctl stop ollama || true
    log_alert "Stopped Ollama daemon."
fi

log_alert "Listening daemons silenced."
