#!/usr/bin/env bash
# mom/sensors.sh - Hardware Sensors Blackout
# Mutes all microphones and unbinds/unloads webcam drivers
set -euo pipefail

log_alert() { echo -e "\033[1;31m[MOM:SENSOR]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

log_alert "Neutralizing audio capture and cameras..."

# 1. Hard-mute ALSA audio capture across all soundcards
if command -v amixer >/dev/null 2>&1; then
    amixer set Capture nocap >/dev/null 2>&1 || true
    amixer set Capture 0% >/dev/null 2>&1 || true
    amixer -D pulse set Capture nocap >/dev/null 2>&1 || true
    amixer -D pulse set Capture 0% >/dev/null 2>&1 || true
    log_alert "Microphone input muted and capture disabled."
fi

# 2. PipeWire / PulseAudio Source Mute
if command -v wpctl >/dev/null 2>&1; then
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 >/dev/null 2>&1 || true
elif command -v pactl >/dev/null 2>&1; then
    pactl set-source-mute @DEFAULT_SOURCE@ 1 >/dev/null 2>&1 || true
fi

# 3. Unload webcam video drivers
for mod in uvcvideo videodev; do
    if lsmod | grep -q "^$mod\b"; then
        log_alert "Unloading webcam driver: $mod"
        run_sudo modprobe -r "$mod" 2>/dev/null || true
    fi
done

log_alert "Sensors neutralized."
