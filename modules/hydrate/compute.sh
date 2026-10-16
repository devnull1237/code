#!/usr/bin/env bash
# modules/hydrate/compute.sh - Hydrate CPU governors, Turbo Boost, and GPU modes
set -euo pipefail

run_sudo() { [ "$(id -u)" -eq 0 ] && "$@" || sudo "$@"; }

apply_compute() {
    local json="$1"
    local gov_target turbo_target gpu_target

    gov_target="$(jq -r '.compute.cpu_governor // empty' "$json")"
    turbo_target="$(jq -r '.compute.turbo_boost // empty' "$json")"
    gpu_target="$(jq -r '.compute.gpu_mode // empty' "$json")"

    # 1. CPU Governor
    if [ -n "$gov_target" ]; then
        echo -e "\033[1;34m[HYDRATE:COMPUTE]\033[0m Setting CPU governor to '$gov_target'..."
        for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            [ -f "$gov" ] && echo "$gov_target" | run_sudo tee "$gov" >/dev/null 2>&1 || true
        done
    fi

    # 2. Turbo Boost
    if [ "$turbo_target" = "true" ]; then
        echo -e "\033[1;32m[HYDRATE:COMPUTE]\033[0m Turbo Boost enabled."
        [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ] && echo 0 | run_sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1 || true
        [ -f /sys/devices/system/cpu/cpufreq/boost ] && echo 1 | run_sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null 2>&1 || true
    elif [ "$turbo_target" = "false" ]; then
        echo -e "\033[1;33m[HYDRATE:COMPUTE]\033[0m Turbo Boost disabled."
        [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ] && echo 1 | run_sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1 || true
        [ -f /sys/devices/system/cpu/cpufreq/boost ] && echo 0 | run_sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null 2>&1 || true
    fi

    # 3. GPU Mode (Nvidia persistence / performance if nvidia-smi exists)
    if [ "$gpu_target" = "max-performance" ] && command -v nvidia-smi >/dev/null 2>&1; then
        echo -e "\033[1;32m[HYDRATE:COMPUTE]\033[0m Nvidia GPU set to persistence mode."
        run_sudo nvidia-smi -pm 1 2>/dev/null || true
    fi
}

[ -n "${1:-}" ] && [ -f "$1" ] && apply_compute "$1"
