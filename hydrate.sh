#!/usr/bin/env bash
# hydrate.sh - Universal Composable Profile Hydration Engine
# Executes one or more sparse JSON profiles serially from left to right:
# Example: ./hydrate.sh mom low-baseline
# Example: ./hydrate.sh low-baseline gaming
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/profiles"
HYDRATE_DIR="$SCRIPT_DIR/modules/hydrate"

log_info() { echo -e "\033[1;34m[HYDRATE]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

usage() {
    cat <<EOF
Usage: ./hydrate.sh <profile1> [profile2] ...

Profiles are resolved from:
  1. Direct file path: ./path/to/profile.json
  2. Profiles directory: $PROFILES_DIR/<name>.json

Available built-in profiles:
$(ls -1 "$PROFILES_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//' | sed 's/^/  - /')

Examples:
  ./hydrate.sh mom
  ./hydrate.sh mom low-baseline
  ./hydrate.sh low-baseline gaming
  ./hydrate.sh saltflats
EOF
    exit 0
}

[ $# -eq 0 ] && usage

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

    # Execute subsystem handlers only if corresponding keys are present in the JSON fragment
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
    log_info "Initiating serial hydration sequence: $*"
    local start_time
    start_time="$(date +%s)"

    for profile in "$@"; do
        apply_profile "$profile"
    done

    local end_time elapsed
    end_time="$(date +%s)"
    elapsed=$((end_time - start_time))

    echo ""
    log_ok "=================================================="
    log_ok "Hydration sequence completed successfully in ${elapsed}s!"
    log_ok "=================================================="
}

main "$@"
