# Navigation & Directory
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# List files
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Safe defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Custom dev commands
if [ -f "$HOME/.local/bin/devgo" ]; then
    alias devgo="$HOME/.local/bin/devgo"
fi

# Battery statistics
batt() {
    local cap stat
    if [ -d /sys/class/power_supply/BAT0 ]; then
        cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        stat=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        echo "${cap}% (${stat})"
    elif command -v upower >/dev/null 2>&1; then
        local dev
        dev=$(upower -e | grep -m1 'BAT')
        if [ -n "$dev" ]; then
            upower -i "$dev" | awk '/percentage:/ {p=$2} /state:/ {s=$2} END {if (p) print p, "(" s ")"}'
        else
            echo "No battery found"
        fi
    else
        echo "Battery info unavailable"
    fi
}
