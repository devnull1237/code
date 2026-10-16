#!/usr/bin/env bash
# modules/hydrate/services.sh - Hydrate system services (MongoDB, Redis, Ollama)
set -euo pipefail

run_sudo() { [ "$(id -u)" -eq 0 ] && "$@" || sudo "$@"; }

apply_services() {
    local json="$1"

    # 1. Services to suspend / stop
    while IFS= read -r svc; do
        [ -z "$svc" ] && continue
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "\033[1;33m[HYDRATE:SVC]\033[0m Stopping service: $svc"
            run_sudo systemctl stop "$svc" || true
        fi
    done < <(jq -r '.services_to_suspend[]? // empty' "$json")

    # 2. Services declared in .services object (e.g. "mongodb": true/false)
    for svc_key in mongodb redis ollama; do
        local state
        state="$(jq -r ".services.$svc_key // empty" "$json")"
        [ -z "$state" ] && continue

        local sys_svc="$svc_key"
        [ "$svc_key" = "mongodb" ] && sys_svc="mongod"
        [ "$svc_key" = "redis" ] && sys_svc="redis-server"

        if [ "$state" = "true" ]; then
            if ! systemctl is-active --quiet "$sys_svc" 2>/dev/null; then
                echo -e "\033[1;32m[HYDRATE:SVC]\033[0m Starting service: $sys_svc"
                run_sudo systemctl start "$sys_svc" 2>/dev/null || true
            fi
        elif [ "$state" = "false" ]; then
            if systemctl is-active --quiet "$sys_svc" 2>/dev/null; then
                echo -e "\033[1;33m[HYDRATE:SVC]\033[0m Stopping service: $sys_svc"
                run_sudo systemctl stop "$sys_svc" 2>/dev/null || true
            fi
        fi
    done
}

[ -n "${1:-}" ] && [ -f "$1" ] && apply_services "$1"
