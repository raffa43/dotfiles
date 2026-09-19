# 1. Base CachyOS Settings & Oh-My-Zsh
DISABLE_MAGIC_FUNCTIONS="false"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

if [[ "$OSTYPE" == "darwin"* ]]; then
    export ZSH="$HOME/.oh-my-zsh"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export ZSH="/usr/share/oh-my-zsh"
    zstyle :omz:plugins:ssh-agent helper ksshaskpass

    #[[ ! -d "$ZSH" ]] && export ZSH="$HOME/.oh-my-zsh"
fi


zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent honor-existing yes
zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain␍
zstyle :omz:plugins:ssh-agent identities ~/.config/ssh/{id_ed2551}

plugins=(
  git 
  fzf 
  extract 

  ssh 
  ssh-agent
  
  screen
  kitty
  alias-finder

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
    export FZF_BASE=/usr/share/fzf

    # Linux Plugin Sourcing
    [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    [[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    [[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh

    # MacOs
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS Aliases
    # alias mpv="/Applications/mpv.app/Contents/MacOS/mpv"
    # macOS Plugin Sourcing
    HOMEBREW_PREFIX=$(brew --prefix)

    AUTOSUGGEST=$ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    HISTORY_SEARCH=$ZSH/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    SYNTAX_HIGHLIGHT=$ZSH/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

    #[[ -f $AUTOSUGGEST ]] && source $AUTOSUGGEST 

    #[[ -f $SYNTAX_HIGHLIGHT ]] && source $SYNTAX_HIGHLIGHT

    #[[ -f $HISTORY_SEARCH ]] && source $HISTORY_SEARCH

fi



ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets pattern cursor)


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
