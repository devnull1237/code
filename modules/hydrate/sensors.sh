#!/usr/bin/env bash
# modules/hydrate/sensors.sh - Hydrate audio capture and webcams
set -euo pipefail

run_sudo() { [ "$(id -u)" -eq 0 ] && "$@" || sudo "$@"; }

apply_sensors() {
    local json="$1"
    local mic_target cam_target vol_target

    mic_target="$(jq -r '.sensors.microphone // .audio.microphone // empty' "$json")"
    cam_target="$(jq -r '.sensors.camera // empty' "$json")"
    vol_target="$(jq -r '.audio.capture_volume // empty' "$json")"

    # 1. Microphone
    if [ "$mic_target" = "muted" ]; then
        echo -e "\033[1;33m[HYDRATE:SENSOR]\033[0m Muting microphones..."
        command -v amixer >/dev/null 2>&1 && amixer set Capture nocap >/dev/null 2>&1 || true
        command -v wpctl >/dev/null 2>&1 && wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 2>/dev/null || true
    elif [ "$mic_target" = "active" ]; then
        echo -e "\033[1;32m[HYDRATE:SENSOR]\033[0m Activating microphones..."
        command -v amixer >/dev/null 2>&1 && amixer set Capture cap >/dev/null 2>&1 || true
        command -v wpctl >/dev/null 2>&1 && wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 2>/dev/null || true
        [ -n "$vol_target" ] && command -v amixer >/dev/null 2>&1 && amixer set Capture "${vol_target}%" >/dev/null 2>&1 || true
    fi

    # 2. Camera Driver
    if [ "$cam_target" = "unloaded" ]; then
        echo -e "\033[1;33m[HYDRATE:SENSOR]\033[0m Unloading camera driver..."
        run_sudo modprobe -r uvcvideo 2>/dev/null || true
    elif [ "$cam_target" = "active" ]; then
        echo -e "\033[1;32m[HYDRATE:SENSOR]\033[0m Loading camera driver..."
        run_sudo modprobe uvcvideo 2>/dev/null || true
    fi
}

[ -n "${1:-}" ] && [ -f "$1" ] && apply_sensors "$1"
