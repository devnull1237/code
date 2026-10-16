#!/usr/bin/env bash
# bootstrap.sh - Zero-to-running machine spin-up and top-off orchestrator
# Idempotent provisioning & synchronization for Linux Mint machines
# Designed for Day-1 setup and repeated top-off runs across multiple machines.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

log_info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_ok()   { echo -e "\033[1;32m[OK]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

usage() {
    cat <<EOF
Usage: ./bootstrap.sh [OPTIONS]

Options:
  --all            Run complete bootstrap / provisioning sequence (default)
  --system         Run system upgrade, parallel APT/Nala, and base certs
  --packages       Run package and browser installation only
  --security       Run SSH, UFW firewall, and Git config setup only
  --power          Run lid close, TLP, and power profile setup only
  --dotfiles       Run dotfile symlinking and directory layout setup only
  --database       Run SQLite, Redis, and MongoDB database setup only
  --python         Run Python3, pip, and developer tools setup only
  --ai             Run Ollama and Granite model downloads only
  -h, --help       Show this help message
EOF
    exit 0
}

main() {
    local run_all=true
    local run_sys=false
    local run_pkg=false
    local run_sec=false
    local run_pwr=false
    local run_dot=false
    local run_db=false
    local run_py=false
    local run_ai=false

    if [ $# -gt 0 ]; then
        run_all=false
        while [ $# -gt 0 ]; do
            case "$1" in
                --all) run_all=true ;;
                --system) run_sys=true ;;
                --packages) run_pkg=true ;;
                --security) run_sec=true ;;
                --power) run_pwr=true ;;
                --dotfiles) run_dot=true ;;
                --database) run_db=true ;;
                --python) run_py=true ;;
                --ai) run_ai=true ;;
                -h|--help) usage ;;
                *) echo "Unknown option: $1"; usage ;;
            esac
            shift
        done
    fi

    local start_time
    start_time="$(date +%s)"
    log_info "Starting Mint machine bootstrap from $SCRIPT_DIR"

    if [ "$run_all" = true ] || [ "$run_sys" = true ]; then
        "$MODULES_DIR/system.sh"
    fi

    if [ "$run_all" = true ] || [ "$run_pkg" = true ]; then
        "$MODULES_DIR/packages.sh"
    fi

    if [ "$run_all" = true ] || [ "$run_sec" = true ]; then
        "$MODULES_DIR/security.sh"
    fi

    if [ "$run_all" = true ] || [ "$run_pwr" = true ]; then
        "$MODULES_DIR/power.sh"
    fi

    if [ "$run_all" = true ] || [ "$run_dot" = true ]; then
        "$MODULES_DIR/dotfiles.sh"
    fi

    if [ "$run_all" = true ] || [ "$run_db" = true ]; then
        "$MODULES_DIR/database.sh"
    fi

    if [ "$run_all" = true ] || [ "$run_py" = true ]; then
        "$MODULES_DIR/python.sh"
    fi

    if [ "$run_all" = true ] || [ "$run_ai" = true ]; then
        "$MODULES_DIR/ai.sh"
    fi

    local end_time elapsed
    end_time="$(date +%s)"
    elapsed=$((end_time - start_time))

    echo ""
    log_ok "=========================================="
    log_ok "Bootstrap sequence finished successfully in ${elapsed}s!"
    log_ok "=========================================="
}

main "$@"
