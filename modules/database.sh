#!/usr/bin/env bash
# modules/database.sh - Native database engines (SQLite, Redis, MongoDB)
# Runs as bare-metal systemd services without Docker
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

# 1. SQLite3
install_sqlite() {
    log_info "Checking SQLite3..."
    if dpkg -s sqlite3 libsqlite3-dev >/dev/null 2>&1; then
        log_ok "SQLite3 already installed."
    else
        log_info "Installing SQLite3..."
        run_sudo apt-get install -y sqlite3 libsqlite3-dev
        log_ok "SQLite3 installed."
    fi
}

# 2. Redis Server (native broker for Celery)
install_redis() {
    log_info "Checking Redis Server..."
    if dpkg -s redis-server >/dev/null 2>&1; then
        log_ok "Redis Server already installed."
    else
        log_info "Installing Redis Server..."
        run_sudo apt-get install -y redis-server
    fi

    # Ensure redis is enabled and active
    if ! systemctl is-active --quiet redis-server && ! systemctl is-active --quiet redis; then
        log_info "Enabling and starting Redis service..."
        run_sudo systemctl enable --now redis-server 2>/dev/null || run_sudo systemctl enable --now redis
        log_ok "Redis service active."
    else
        log_ok "Redis service is already running."
    fi
}

# 3. MongoDB Community Server
install_mongodb() {
    log_info "Checking MongoDB..."
    if command -v mongod >/dev/null 2>&1 || dpkg -s mongodb-org >/dev/null 2>&1; then
        log_ok "MongoDB is already installed."
    else
        log_info "Configuring MongoDB Community repository..."
        local keyring="/etc/apt/keyrings/mongodb-server-7.0.gpg"
        local list_file="/etc/apt/sources.list.d/mongodb-org-7.0.list"

        run_sudo mkdir -p /etc/apt/keyrings
        if [ ! -f "$keyring" ]; then
            curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor | run_sudo tee "$keyring" >/dev/null
        fi

        # Detect Ubuntu codename underlying Linux Mint (e.g., jammy, noble)
        local ubuntu_codename
        ubuntu_codename="$(grep UBUNTU_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2 || true)"
        if [ -z "$ubuntu_codename" ]; then
            ubuntu_codename="$(lsb_release -cs 2>/dev/null || echo "jammy")"
        fi

        if [ ! -f "$list_file" ]; then
            echo "deb [arch=amd64,arm64 signed-by=$keyring] https://repo.mongodb.org/apt/ubuntu ${ubuntu_codename}/mongodb-org/7.0 multiverse" | run_sudo tee "$list_file" >/dev/null
        fi

        run_sudo apt-get update -qq
        run_sudo apt-get install -y mongodb-org
        log_ok "MongoDB installed."
    fi

    # Ensure mongod is enabled and active
    if ! systemctl is-active --quiet mongod; then
        log_info "Enabling and starting mongod service..."
        run_sudo systemctl daemon-reload
        run_sudo systemctl enable --now mongod
        log_ok "MongoDB service active."
    else
        log_ok "MongoDB service is already running."
    fi
}

main() {
    log_info "--- Running Module: database ---"
    install_sqlite
    install_redis
    install_mongodb
    log_ok "Database module complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
