# `~/code` — Linux Mint Zero-to-Running Machine Hydration & Dotfiles

A lean, low-level system configuration, shell dotfiles, and automated machine hydration engine tailored for **Linux Mint**. 

It handles everything from a clean ISO install on day 1 to ongoing synchronization, emergency hardening ripcords, and performance profiles across multiple machines.

---

## 🚀 Fresh Mint Install (Day 1 Spin-Up)

On a freshly installed Linux Mint ISO, open your terminal and run this **single command**:

```bash
git clone https://github.com/telosdevgroup/code.git ~/code && ~/code/bootstrap.sh
```

*(Note: We clone via HTTPS initially because your SSH key isn't generated or registered on GitHub yet).*

### What Happens Automatically:
1. **Parallel APT & Fedora-Style Logs**: Tunes APT for multi-connection downloads, installs `nala`, and performs a full system upgrade.
2. **Core Toolchain & Browsers**: Installs `tmux`, `neovim`, `xclip`, `git`, `btop`, `powertop`, `upower`, Google Chrome, and Tor Browser.
3. **Security & Firewall**: Enables OpenSSH server, locks UFW firewall (inbound SSH allowed), and generates your `ed25519` SSH key for GitHub.
4. **Power & Battery**: Configures TLP for low CPU wakeups, lid-close screen-off (without sleeping), and sets all Cinnamon desktop power GUI sliders.
5. **Dotfiles**: Backs up stock Mint dotfiles to `~/.dotfiles_backup/` and symlinks `.bashrc`, `.bash_aliases`, `.inputrc`, and `.tmux.conf` into `$HOME`.
6. **Databases (Bare-Metal)**: Installs and enables Redis (Celery broker), MongoDB 8.0 Community, and SQLite3 (no Docker overhead).
7. **Python & AI**: Installs Python3 dev headers, build tools, Ollama daemon, and pre-pulls IBM `granite4.2:3b` and `granite4.2:8b`.

---

## ⚡ Daily Drivers & Key Utilities

### 1. `freshenup`
Top-off, update, and synchronize system packages, dotfiles, services, and local AI models on any machine at any time:
```bash
freshenup
```
Supports granular flags: `--system`, `--packages`, `--security`, `--power`, `--dotfiles`, `--database`, `--python`, `--ai`.

### 2. `hydrate` (Composable Serial Profiles)
Apply declarative JSON state fragments serially like LEGO blocks:
```bash
hydrate <profile1> [profile2] ...
```
Examples:
- `hydrate mom low-baseline` (Emergency recovery: unblock Wi-Fi & audio, keep background daemons dead)
- `hydrate saltflats gaming` (Full throttle: uncapped CPU/GPU performance + sub-5ms PipeWire audio & launchers)
- `hydrate mom` (Cold metal ripcord state)

### 3. `mom` (Metal Over Moss Ripcord)
Instant emergency hardening. Zero confirmations, zero prompts:
```bash
mom
```
- Hard blocks all RF radios (`rfkill`), unloads Bluetooth, and kills Wi-Fi interfaces.
- Hard mutes microphones (`amixer nocap / 0%`) and unloads webcam drivers (`uvcvideo`).
- Drops broadcast beacons (mDNS/CUPS) and locks UFW to inbound SSH over wired Ethernet umbilical only.
- Kills game launchers, distraction apps, and disconnects VPNs.
- Spawns a 3-pane `mom-triage` tmux cockpit (`agy` + editor + shell) and enables phone remote control.

### 4. `proj [dir]` (Project Workspace Spawner)
Instant paired workspace in tmux:
```bash
proj ~/code
```
Opens or attaches to a dedicated session with **`agy` agent on the left (58%)** and an **interactive bash prompt on the right (42%)**.

---

## ⚙️ Declarative Manifest: `settings.json`

All tool defaults, package lists, active services, AI models, and app kill targets are centrally declared in `settings.json`:
- `tools.primary_browser`: `firefox`
- `tools.primary_cli_editor`: `nvim`
- `ai.models`: `["granite4.2:3b", "granite4.2:8b"]`
- `packages.extra_cli`: Additional packages to install during freshenup
- `mom.kill_launchers` / `kill_distractions`: Process names killed on ripcord

---

## 📁 Repository Layout

```
~/code/
├── bootstrap.sh -> freshenup.sh  # Day 1 spin-up entrypoint
├── freshenup.sh                  # Ongoing maintenance & top-off driver
├── hydrate.sh                    # Universal composable profile engine
├── mom.sh                        # Emergency hardening ripcord
├── settings.json                 # Declarative software & tool manifest
├── bin/                          # Standalone CLI tools (proj workspace spawner)
├── profiles/                     # Pure JSON state fragments (mom, low-baseline, gaming, saltflats)
├── modules/                      # Idempotent provisioning engines
│   ├── system.sh                 # APT parallel tuning, nala, dist-upgrade
│   ├── packages.sh               # CLI tools, browsers, btop, powertop, mullvad
│   ├── security.sh               # SSH server, UFW firewall, SSH keygen
│   ├── power.sh                  # TLP, lid-close rules, Cinnamon GUI power settings
│   ├── dotfiles.sh               # Symlink engine with automatic backup
│   ├── database.sh               # Bare-metal SQLite, Redis, MongoDB 8.0
│   ├── python.sh                 # Python3, pip, venv, build headers
│   ├── ai.sh                     # Ollama daemon, Granite models
│   └── hydrate/                  # Subsystem hydration handlers (compute, radios, sensors, etc.)
└── dotfiles
    ├── .bashrc                   # Interactive shell, prompt with git status
    ├── .bash_aliases             # freshenup, mom, proj, hydrate, batt
    ├── .inputrc                  # Tab cycling & history search
    └── .tmux.conf                # Unified X11 clipboard & mouse support
```

---

## 📜 Rules & Conventions
- Maintain the directory distinction: `~/code` (lowercase: system configs & middle-out scripting) vs `~/Code` (uppercase: application projects).
- Dotfiles in `~/code/` are symlinked directly into `/home/dev/`. Always edit source files in `~/code/`.
- Hard Limit: All files must strictly remain under 500 lines (refactor threshold: 371–401 lines).
