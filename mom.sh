#!/usr/bin/env bash
# mom.sh - Metal Over Moss (MOM) Ripcord
# Zero hesitation, zero prompts: emergency lockdown & triage cockpit deployment
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/mom" ]; then
    MOM_DIR="$SCRIPT_DIR/mom"
else
    MOM_DIR="$SCRIPT_DIR"
fi

cat <<'EOF'
  __  __  ___  __  __ 
 |  \/  |/ _ \|  \/  |
 | |\/| | | | | |\/| |  [ METAL OVER MOSS ]
 | |  | | |_| | |  | |  === EMERGENCY HARDENING RIPCORD PULLED ===
 |_|  |_|\___/|_|  |_|  Shrink to moss, encase in metal.

EOF

start_time="$(date +%s)"

# 1. Kill all RF, Bluetooth, and wireless interfaces
"$MOM_DIR/radios.sh"

# 2. Mute microphones, unbind webcams
"$MOM_DIR/sensors.sh"

# 3. Terminate discovery beacons, restrict network to wired umbilical + SSH
"$MOM_DIR/network.sh"

# 4. Silence databases and unnecessary daemons
"$MOM_DIR/daemons.sh"

# 5. Flush clipboards, buffers, and drop caches
"$MOM_DIR/sanitize.sh"

# 6. Deploy action cockpit (tmux with agy + shell, remote-control for phone, Firefox)
"$MOM_DIR/cockpit.sh"

end_time="$(date +%s)"
elapsed=$((end_time - start_time))

echo ""
echo -e "\033[1;32m[MOM] Metal Over Moss successfully deployed in ${elapsed}s.\033[0m"
echo -e "\033[1;36m[MOM] Wired umbilical active. Triage cockpit ready: tmux attach -t mom-triage\033[0m"
