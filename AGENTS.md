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

> **Rule for Agents**: When editing shell dotfiles, always modify the source files in `/home/dev/code/` (or verify that the symlink in `~` remains intact). Do not overwrite symlinks in `~` with regular files.

---

## 3. Git & Remote
- **Repository**: `git@github.com:telosdevgroup/code.git`
- **Default Branch**: `main`
- **Author Identity**: Kyle Carlson (`thekylecarlson@gmail.com`)
- SSH authentication is configured for `telosdevgroup` on GitHub. Use SSH URLs (`git@github.com:...`).

---

## 4. Shell & Tools
- **Default Shell**: Bash (with `bash-completion` and optimized Readline settings via `.inputrc`).
- **Aliases & Helpers**:
  - Defined in `.bash_aliases` and sourced by `.bashrc`.
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

## 6. Machine Bootstrap & Organization
The ultimate purpose of this repository is **zero-to-running machine spin-up**. On any fresh laptop, cloning `~/code` should install dependencies, configure symlinks, restore settings, and bring up the complete development environment.

### Target Repository Layout:
- `bootstrap.sh` (or `install.sh`): Idempotent, modular onboarding script to provision apt packages, setup tools, create symlinks, and configure defaults.
- `bin/` or `tools/`: Standalone helper CLI scripts and lightweight utilities added to `$PATH`.
- `dotfiles/`: Dotfiles organized cleanly (symlinked into `$HOME`).
- `config/`: App-specific configuration files (e.g., Neovim, terminal configs, XFCE/desktop tweaks).

> **Guideline for Agents**: Keep provisioning scripts idempotent (`-y` flags, check if already installed or symlinked, don't clobber user data without backups). Everything created here should be reproducible across new machines.


