#!/usr/bin/env bash
# modules/hydrate/launchers.sh - Hydrate target launchers & applications
set -euo pipefail

apply_launchers() {
    local json="$1"

    # Only attempt launching apps if an active display session is present
    if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
        return 0
    fi

    # Check for .launchers array in the profile JSON
    local launcher_count
    launcher_count="$(jq '.launchers | length // 0' "$json" 2>/dev/null || echo "0")"

    if [ "$launcher_count" -gt 0 ]; then
        for i in $(seq 0 $((launcher_count - 1))); do
            local name bin cmd
            name="$(jq -r ".launchers[$i].name" "$json")"
            bin="$(jq -r ".launchers[$i].binary" "$json")"
            cmd="$(jq -r ".launchers[$i].command" "$json")"

            if command -v "$bin" >/dev/null 2>&1; then
                if ! pgrep -fi "$bin" >/dev/null 2>&1; then
                    echo -e "\033[1;32m[HYDRATE:APP]\033[0m Launching $name..."
                    nohup $cmd >/dev/null 2>&1 &
                else
                    echo -e "\033[1;34m[HYDRATE:APP]\033[0m $name is already running."
                fi
            fi
        done
    fi
}

[ -n "${1:-}" ] && [ -f "$1" ] && apply_launchers "$1"
