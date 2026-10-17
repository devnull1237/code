#!/usr/bin/env bash
# hydrate.sh - Nerdbox Provisioning & Composable Hydration Engine
# If called without arguments: provisions the full Cinnamon nerdbox (dev, AI, privacy, services)
# If called with arguments: applies sparse JSON profiles (e.g. ./hydrate.sh gaming, ./hydrate.sh mom)
# Enter sudo once, step away for ~5 min.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/profiles"
HYDRATE_DIR="$SCRIPT_DIR/modules/hydrate"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap.sh"

log_info() { echo -e "\033[1;34m[HYDRATE]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

init_sudo_keepalive() {
    run_sudo -v
    while true; do run_sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    KEEPALIVE_PID=$!
    trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

apply_profile() {
    local profile_arg="$1"
    local json_path=""

    if [ -f "$profile_arg" ]; then
        json_path="$profile_arg"
    elif [ -f "$PROFILES_DIR/${profile_arg}.json" ]; then
        json_path="$PROFILES_DIR/${profile_arg}.json"
    elif [ -f "$PROFILES_DIR/${profile_arg}" ]; then
        json_path="$PROFILES_DIR/${profile_arg}"
    else
        echo -e "\033[1;31m[ERROR]\033[0m Profile '$profile_arg' not found."
        return 1
    fi

    local profile_name desc
    profile_name="$(jq -r '.profile // "custom"' "$json_path" 2>/dev/null || basename "$json_path")"
    desc="$(jq -r '.description // "Applying profile fragment"' "$json_path" 2>/dev/null || echo "")"

    echo ""
    log_info "=== Applying Profile Fragment: \033[1;36m$profile_name\033[0m ==="
    [ -n "$desc" ] && echo -e "    \033[0;90m$desc\033[0m"

    if [ "$(jq 'has("radios")' "$json_path")" = "true" ]; then
        "$HYDRATE_DIR/radios.sh" "$json_path"
    fi

    if [ "$(jq 'has("sensors") or has("audio")' "$json_path")" = "true" ]; then
        "$HYDRATE_DIR/sensors.sh" "$json_path"
    fi

    if [ "$(jq 'has("compute")' "$json_path")" = "true" ]; then
        "$HYDRATE_DIR/compute.sh" "$json_path"
    fi

    if [ "$(jq 'has("services") or has("services_to_suspend")' "$json_path")" = "true" ]; then
        "$HYDRATE_DIR/services.sh" "$json_path"
    fi

    if [ "$(jq 'has("launchers")' "$json_path")" = "true" ]; then
        "$HYDRATE_DIR/launchers.sh" "$json_path"
    fi

    log_ok "Layer applied: $profile_name"
}

main() {
    export DEBIAN_FRONTEND=noninteractive
    local start_time
    start_time="$(date +%s)"

    # If profiles are passed as arguments, execute composable profile mode
    if [ $# -gt 0 ]; then
        if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
            cat <<EOF
Usage: ./hydrate.sh [profile1] [profile2] ...

No arguments:
  Runs full machine hydration (dev, AI, privacy, services, system top-off).

With profile arguments:
  Applies sparse JSON profile layers from left to right.
  Available profiles: $(ls -1 "$PROFILES_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//' | tr '\n' ' ')
EOF
            exit 0
        fi

        log_info "Initiating composable profile hydration: $*"
        init_sudo_keepalive
        for profile in "$@"; do
            apply_profile "$profile"
        done
    else
        # Default zero-argument mode: Complete Nerdbox Hydration
        log_info "Initiating full Nerdbox machine hydration (step away for ~5 min)..."
        init_sudo_keepalive
        "$BOOTSTRAP_SCRIPT" --all
    fi

    local end_time elapsed
    end_time="$(date +%s)"
    elapsed=$((end_time - start_time))

    echo ""
    log_ok "=================================================="
    log_ok "Hydration sequence completed successfully in ${elapsed}s!"
    log_ok "=================================================="
}

main "$@"
