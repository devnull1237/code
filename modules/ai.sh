#!/usr/bin/env bash
# modules/ai.sh - Ollama installation and local IBM Granite model pulling
set -euo pipefail

log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

install_ollama() {
    log_info "Checking Ollama..."
    if command -v ollama >/dev/null 2>&1; then
        log_ok "Ollama is already installed ($(ollama --version 2>/dev/null || true))."
    else
        log_info "Installing Ollama via official installer..."
        curl -fsSL https://ollama.com/install.sh | sh
        log_ok "Ollama installed."
    fi

    # Ensure ollama service is running
    if ! systemctl is-active --quiet ollama; then
        log_info "Starting Ollama service..."
        sudo systemctl enable --now ollama || true
        # Brief pause to allow the API socket to initialize
        sleep 2
    fi
}

pull_models() {
    log_info "Checking local LLMs..."
    local models=(
        "granite4.2:3b"
        "granite4.2:8b"
    )

    local existing_models
    existing_models="$(ollama list 2>/dev/null || true)"

    for model in "${models[@]}"; do
        # Extract base name to check existence
        local base_name="${model%%:*}"
        if echo "$existing_models" | grep -q "$base_name"; then
            log_ok "Model already present: $model"
        else
            log_info "Pulling model: $model..."
            ollama pull "$model"
            log_ok "Model pulled: $model"
        fi
    done
}

main() {
    log_info "--- Running Module: ai ---"
    install_ollama
    pull_models
    log_ok "AI module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
