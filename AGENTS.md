# AGENTS.md

Welcome to `~/code`. This repository houses shell configuration, dotfiles, low-level scripting, and direct kernel/hardware interfaces ("middle-out").

---

## 1. Directory Context: `~/code` vs `~/Code`
- **`~/code` (lowercase)**: Low-level system scripts, shell dotfiles (`.bashrc`, `.bash_aliases`, `.inputrc`), hardware/sysfs queries (`/sys`, `/proc`), and lightweight CLI utilities.
- **`~/Code` (uppercase)**: Higher-level development projects, applications, and full codebases.
- Maintain this distinction: keep `~/code` lean, fast, and close to the kernel.

---

## 2. Symlink Architecture
Files in this repository are symlinked directly into the user root (`/home/dev`):
- `~/code/.bashrc` &rarr; `~/.bashrc`
- `~/code/.bash_aliases` &rarr; `~/.bash_aliases`
- `~/code/.inputrc` &rarr; `~/.inputrc`
- `~/code/.tmux.conf` &rarr; `~/.tmux.conf`

> **Rule for Agents**: When editing shell dotfiles, always modify the source files in `/home/dev/code/` (or verify that the symlink in `~` remains intact). Do not overwrite symlinks in `~` with regular files.

---

## 3. Git & Local Version Control
- **Posture**: **100% Local (Airgapped / Sneakernet via USB)**. No GitHub remote.
- **Default Branch**: `main`
- **Author Identity**: Kyle Carlson (`thekylecarlson@gmail.com`)
- Changes are committed locally and synchronized across machines via removable USB drive.

---

## 4. Shell & Tools
- **Default Shell**: Bash (with `bash-completion` and optimized Readline settings via `.inputrc`).
- **Terminal Multiplexer**: `tmux` with unified X11 system clipboard integration (`xclip`), mouse support, and Vi keybindings.
- **Aliases & Helpers**:
  - Defined in `.bash_aliases` and sourced by `.bashrc`.
  - `debloat`: Unattended Linux Mint Cinnamon stock purge and service silencing (`~/code/debloat.sh`).
  - `hydrate`: Zero-argument nerdbox provisioning or serial profile engine (`~/code/hydrate.sh [profile1] [profile2]`).
  - `freshenup`: Top-off and synchronize system packages, dotfiles, services, and AI models (`~/code/freshenup.sh`).
  - `mom`: Metal Over Moss emergency hardening ripcord and triage cockpit (`~/code/mom.sh` & `~/code/mom/`).
  - `proj`: Per-project tmux workspace spawner (`agy` + shell) (`~/code/bin/proj [dir]`).
  - `batt`: Quick battery status inspecting `/sys/class/power_supply/BAT0/` (fallback to `upower`).
  - `devgo`: Custom environment unlocker and launcher for `agy`.
- **Guidelines for New Utilities**:
  - Prefer reading from `/sys/` and `/proc/` directly over heavy userspace tools when possible.
  - Keep utilities modular and documented in `.bash_aliases` or dedicated helper scripts under this repository.

---

## 5. File Size & Refactoring Rules
- **Hard Limit**: All files must remain strictly **under 500 lines**.
- **Refactoring Threshold (371–401 lines)**:
  - When any file approaches between **371 and 401 lines**, stop and formulate a plan to refactor and modularize.
  - Split large configs or scripts into focused modules (e.g., dedicated topic files sourced by the main entrypoint).

---

## 6. Machine Bootstrap & Synchronization
The ultimate purpose of this repository is **zero-to-running machine spin-up and ongoing synchronization** across Linux Mint machines. On any fresh install or existing box, running `freshenup` (or `./bootstrap.sh` &rarr; `./freshenup.sh`) will provision dependencies, configure symlinks, restore settings, pull models, and top off the complete development environment idempotently.

### Modular Layout:
- `freshenup.sh` (symlinked as `bootstrap.sh`): Main orchestrator CLI driver (supports `--all`, `--system`, `--packages`, `--security`, `--power`, `--dotfiles`, `--database`, `--python`, `--ai`).
- `modules/`:
  - `system.sh`: APT parallel connection tuning, nala (Fedora-like logs/downloads), base certificates, and full system upgrade.
  - `packages.sh`: Core CLI utilities (`tmux`, `xclip`, `neovim`, `git`, `ufw`, `openssh`), monitoring (`btop`, `powertop`), browsers (Chrome, Firefox, Tor), and Mullvad VPN.
  - `security.sh`: OpenSSH service enablement, UFW firewall rules, ed25519 SSH key generation, and Git config.
  - `power.sh`: Systemd logind lid-close rules (screen-off without sleep) and power-profiles-daemon.
  - `dotfiles.sh`: Idempotent symlink creation into `$HOME` with automatic backup of existing files.
  - `database.sh`: Bare-metal systemd services for SQLite, Redis (Celery broker), and MongoDB.
  - `python.sh`: Python3, pip, venv, and development compiler headers.
  - `ai.sh`: Ollama daemon installation and IBM Granite model pull (`granite4.2:3b`, `granite4.2:8b`).



