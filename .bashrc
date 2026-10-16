# ~/.bashrc - Clean, fast Bash configuration

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Shell options
shopt -s autocd        # Type directory path directly to cd
shopt -s globstar      # Recursive ** globbing
shopt -s checkwinsize  # Auto-update window dimensions
shopt -s cdspell       # Autocorrect minor directory typos
shopt -s dirspell      # Autocorrect typos during tab completion
shopt -s histappend    # Append to history file, do not overwrite

# History configuration
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=5000
HISTFILESIZE=10000
HISTTIMEFORMAT="%F %T "

# Enable programmable completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Prompt construction (clean, fast, no git noise)
build_prompt() {
    local EXIT_CODE=$?
    local RESET='\[\033[00m\]'
    local BOLD_BLUE='\[\033[01;34m\]'
    local BOLD_GREEN='\[\033[01;32m\]'
    local RED='\[\033[00;31m\]'

    local STATUS_COLOR="$BOLD_GREEN"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS_COLOR="$RED"
    fi

    local VENV_PROMPT=""
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        VENV_PROMPT="(${VIRTUAL_ENV##*/}) "
    fi

    PS1="${VENV_PROMPT}${BOLD_GREEN}\u@\h${RESET}:${BOLD_BLUE}\w${RESET} ${STATUS_COLOR}\$${RESET} "
}
PROMPT_COMMAND="build_prompt"

# Color support for ls and common tools
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Load aliases
if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi

# User bin in PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
