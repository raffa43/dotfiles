# 1. Base CachyOS Settings & Oh-My-Zsh
DISABLE_MAGIC_FUNCTIONS="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

#MacOS Oh-My-Zsh setup
if [[ "$OSTYPE" == "darwin"* ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain

#CachyOS Oh-My-Zsh setup
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export ZSH="/usr/share/oh-my-zsh"
    zstyle :omz:plugins:ssh-agent helper ksshaskpass
fi

zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent honor-existing yes
zstyle :omz:plugins:ssh-agent identities ~/.ssh/id_ed2551

plugins=(
  git 
  fzf 
  extract 

  ssh 
  ssh-agent
  
  kitty

  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
)


[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# 2. History & Colors
# Do not save commands that start with a space
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS

export HISTCONTROL=ignoreboth
export HISTORY_IGNORE="(\&|[bf]g|c|clear|history|exit|q|pwd|* --help)"
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

export LESS_TERMCAP_md="$(tput bold 2> /dev/null; tput setaf 2 2> /dev/null)"
export LESS_TERMCAP_me="$(tput sgr0 2> /dev/null)"

# 3. Universal Keybindings & Aliases
bindkey '^z' undo
bindkey '^[^?' backward-kill-word
bindkey '^[w' backward-kill-word

alias make="make -j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"
alias ninja="ninja -j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"
alias n="ninja"
alias c="clear"
alias dotgit='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# 4. OS-Specific Plugins & Aliases
if [[ "$OSTYPE" == "linux-gnu"* ]]; then

    # Arch/CachyOS Aliases
    alias rmpkg="sudo pacman -Rsn"
    alias cleanch="sudo pacman -Scc"
    alias fixpacman="sudo rm /var/lib/pacman/db.lck"
    alias update="sudo pacman -Syu"
    alias apt="man pacman"
    alias apt-get="man pacman"
    alias please="sudo"
    alias tb="nc termbin.com 9999"
    alias cleanup="sudo pacman -Rsn \$(pacman -Qtdq)"
    alias jctl="journalctl -p 3 -xb"
    alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
    alias paru-s="paru -S --sudoloop --needed --noconfirm"
    # alias gamemoderun="game-performance"

    export FZF_BASE=/usr/share/fzf


    #[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && 
    source /opt/miniconda3/etc/profile.d/conda.sh

# MacOs
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS Plugin Sourcing
    #HOMEBREW_PREFIX=$(brew --prefix)
    # Disabled in favor of MacPorts

    MACPORTS_PREFIX="/opt/local"
    export MACPORTS_PREFIX

    # MacOS Aliases
    alias mpwd='mpv --playlist=$(pwd) '

    #AUTOSUGGEST=$ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    #HISTORY_SEARCH=$ZSH/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    #SYNTAX_HIGHLIGHT=$ZSH/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

    #[[ -f $AUTOSUGGEST ]] && source $AUTOSUGGEST 

    #[[ -f $SYNTAX_HIGHLIGHT ]] && source $SYNTAX_HIGHLIGHT

    #[[ -f $HISTORY_SEARCH ]] && source $HISTORY_SEARCH
    #
    #
    source /opt/local/share/fzf/shell/key-bindings.zsh
    source /opt/local/share/fzf/shell/completion.zsh


fi

ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets pattern cursor)

export FZF_DEFAULT_OPTS="--color=bg+:#0d1b2a,bg:#000000,spinner:#00ff87,hl:#00dfff,fg:#ffffff,header:#00dfff,info:#00ff87,pointer:#00ff87,marker:#00ff87,prompt:#00ff87,hl+:#00ff87"

# Explicitly declare the associative array to prevent subscript errors
typeset -A ZSH_HIGHLIGHT_STYLES

# Mid-tone high-saturation Green/Blue/Teal (readable on both #000000 and 85% white)
ZSH_HIGHLIGHT_STYLES[command]='fg=#00b359,bold'              # Deep emerald green
ZSH_HIGHLIGHT_STYLES[alias]='fg=#0099cc,bold'                # Strong cerulean blue
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#00acc1,bold'              # Deep cyan
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#0077ff,bold' # Vivid cobalt blue
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#0077ff,bold' # Vivid cobalt blue
ZSH_HIGHLIGHT_STYLES[path]='fg=#26a69a,underline'            # Rich teal (replaces white)
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#00bfa5,bold'             # Mint-teal

# Only initialize starship if NOT connected via SSH
if [[ -z "$SSH_CONNECTION" ]]; then
    if command -v starship &>/dev/null; then
        eval "$(starship init zsh)"
    fi
fi

# Run fastfetch for all interactive sessions
if [[ -o interactive ]]; then
   fastfetch
fi
