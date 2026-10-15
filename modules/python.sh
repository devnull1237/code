#!/usr/bin/env bash
# modules/python.sh - Python runtime, pip, virtualenv, and build tooling
set -euo pipefail

log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

install_python_env() {
    log_info "Checking Python packages and developer headers..."
    local pkgs=(
        python3
        python3-pip
        python3-venv
        python3-dev
        build-essential
        libssl-dev
        libffi-dev
    )

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_info "Installing missing Python packages: ${missing[*]}"
        run_sudo apt-get update -qq
        run_sudo apt-get install -y "${missing[@]}"
        log_ok "Python developer environment installed."
    else
        log_ok "Python and build tooling are already installed."
    fi
}

main() {
    log_info "--- Running Module: python ---"
    install_python_env
    log_ok "Python module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
