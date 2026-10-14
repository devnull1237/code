# AGENTS.md

Welcome to `~/code`. This repository houses shell configuration, dotfiles, low-level scripting, and direct kernel/hardware interfaces ("middle-out").

---

## 1. Directory Context: `~/code` vs `~/Code`
- **`~/code` (lowercase)**: Low-level system scripts, shell dotfiles (`.zshrc`, `.zsh_aliases`), hardware/sysfs queries (`/sys`, `/proc`), and lightweight CLI utilities.
- **`~/Code` (uppercase)**: Higher-level development projects, applications, and full codebases.
- Maintain this distinction: keep `~/code` lean, fast, and close to the kernel.

---

## 2. Symlink Architecture
Files in this repository are symlinked directly into the user root (`/home/dev`):
- `~/code/.zshrc` &rarr; `~/.zshrc`
- `~/code/.zsh_aliases` &rarr; `~/.zsh_aliases`

> **Rule for Agents**: When editing shell dotfiles, always modify the source files in `/home/dev/code/` (or verify that the symlink in `~` remains intact). Do not overwrite symlinks in `~` with regular files.

---

## 3. Git & Remote
- **Repository**: `git@github.com:telosdevgroup/code.git`
- **Default Branch**: `main`
- **Author Identity**: Kyle Carlson (`thekylecarlson@gmail.com`)
- SSH authentication is configured for `telosdevgroup` on GitHub. Use SSH URLs (`git@github.com:...`).

---

## 4. Shell & Tools
- **Default Shell**: Zsh (with `zsh-autosuggestions` and `zsh-syntax-highlighting` loaded from `/usr/share/`).
- **Aliases & Helpers**:
  - Defined in `.zsh_aliases` and sourced by `.zshrc`.
  - `batt`: Quick battery status inspecting `/sys/class/power_supply/BAT0/` (fallback to `upower`).
  - `devgo`: Custom environment unlocker and launcher for `agy`.
- **Guidelines for New Utilities**:
  - Prefer reading from `/sys/` and `/proc/` directly over heavy userspace tools when possible.
  - Keep utilities modular and documented in `.zsh_aliases` or dedicated helper scripts under this repository.
