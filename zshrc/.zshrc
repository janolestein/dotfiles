# ══════════════════════════════════════════════════════════════════════════════
#  Works on Arch and macOS. Optional tools are only used when installed:
#    nvim fzf bat zoxide starship fd eza
#  Startup profiling:  ZSH_PROFILE=1 zsh -i -c exit
# ══════════════════════════════════════════════════════════════════════════════
[[ -n $ZSH_PROFILE ]] && zmodload zsh/zprof

# ══════════════════════════════════════════════════════════════════════════════
#  PATH / fpath  — first, so everything below finds its binaries
# ══════════════════════════════════════════════════════════════════════════════
typeset -U path PATH fpath FPATH        # drop duplicate entries automatically

# Homebrew (macOS): only if .zprofile hasn't set it up already
if [[ $OSTYPE == darwin* && -z $HOMEBREW_PREFIX ]]; then
    for _p in /opt/homebrew /usr/local; do
        [[ -x $_p/bin/brew ]] && { eval "$($_p/bin/brew shellenv)"; break }
    done
    unset _p
fi
[[ -n $HOMEBREW_PREFIX ]] && fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

path=($HOME/.local/bin $path)

export EDITOR='nvim'
export VISUAL='nvim'

setopt extended_glob
setopt interactive_comments
setopt no_flow_control                  # frees Ctrl-S / Ctrl-Q

ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR

# Source a tool's init script from a cache file instead of running
# `eval "$(tool init)"` every time (saves one process per tool per shell).
# The cache is rebuilt when the tool binary or this .zshrc is newer.
_cached_init() {   # usage: _cached_init <command> [args...]
    (( $+commands[$1] )) || return 1
    local cache=$ZSH_CACHE_DIR/init-$1.zsh
    if [[ ! -s $cache || $commands[$1] -nt $cache || ${ZDOTDIR:-$HOME}/.zshrc -nt $cache ]]; then
        "$@" >| $cache 2>/dev/null || { rm -f $cache; return 1 }
    fi
    source $cache
}

# ══════════════════════════════════════════════════════════════════════════════
#  Zinit bootstrap
# ══════════════════════════════════════════════════════════════════════════════
declare -A ZINIT
ZINIT[ZCOMPDUMP_PATH]=$ZSH_CACHE_DIR/zcompdump     # keep $HOME clean

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d $ZINIT_HOME ]]; then
    mkdir -p "${ZINIT_HOME:h}"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# compinit is deferred (see Plugins). Until it runs, queue compdef calls from
# tools like zoxide so their completions aren't silently skipped.
compdef() { ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" ) }

_zsh_compinit() {
    local dump=${ZINIT[ZCOMPDUMP_PATH]}
    autoload -Uz compinit
    if [[ -n $dump(#qN.mh+24) ]]; then
        compinit -i -d $dump; touch $dump   # >24h old: full security check
    else
        compinit -C -d $dump                # fresh: skip the check
    fi
    _comp_options+=(globdots)               # Tab completes dotfiles without typing "."
    # compile the dump in the background so the next shell loads it faster
    { [[ $dump.zwc -nt $dump ]] || zcompile $dump } &!
}

# ══════════════════════════════════════════════════════════════════════════════
#  Plugins — turbo mode: loaded right after the first prompt is drawn,
#  so you can start typing immediately. compinit runs in the same step.
#  (ORDER: completions → autosuggestions → syntax-highlighting last)
# ══════════════════════════════════════════════════════════════════════════════
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # fall back to completions
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20             # don't suggest on big pastes

zinit wait lucid light-mode for \
    atinit'_zsh_compinit; zicdreplay -q' blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions \
    atload'!_zsh_autosuggest_start' \
        zsh-users/zsh-autosuggestions \
        zsh-users/zsh-syntax-highlighting

# ══════════════════════════════════════════════════════════════════════════════
#  Completion styling
# ══════════════════════════════════════════════════════════════════════════════
_cached_init dircolors -b || _cached_init gdircolors -b

zmodload zsh/complist
zstyle ':completion:*' menu select                 # arrow-key selectable menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# offer ".." only once you've typed a dot (with globdots, "true" would add
# "." and ".." to every single completion list)
zstyle -e ':completion:*' special-dirs '[[ $PREFIX == (../)#(.|..) ]] && reply=(..)'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"

# ══════════════════════════════════════════════════════════════════════════════
#  History
# ══════════════════════════════════════════════════════════════════════════════
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt extended_history
setopt appendhistory
setopt sharehistory
setopt hist_fcntl_lock                  # safer/faster locking with sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_reduce_blanks
setopt hist_verify

# ══════════════════════════════════════════════════════════════════════════════
#  Directory navigation
# ══════════════════════════════════════════════════════════════════════════════
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_silent

# ══════════════════════════════════════════════════════════════════════════════
#  Keybindings  (ORDER: bindkey -e first, or $EDITOR silently forces vi mode)
# ══════════════════════════════════════════════════════════════════════════════
bindkey -e

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line

# Terminals disagree on escape codes for these keys, so bind every variant
_bind() { local w=$1 k; shift; for k; do bindkey "$k" $w; done }
_bind up-line-or-beginning-search   '^p' '^[[A' '^[OA'   # Ctrl-P / Up
_bind down-line-or-beginning-search '^n' '^[[B' '^[OB'   # Ctrl-N / Down
_bind beginning-of-line     '^[[H' '^[OH' '^[[1~'        # Home
_bind end-of-line           '^[[F' '^[OF' '^[[4~'        # End
_bind delete-char           '^[[3~'                      # Delete
_bind kill-word             '^[[3;5~'                    # Ctrl-Delete
_bind backward-word         '^[[1;5D' '^[[1;3D'          # Ctrl/Alt-Left
_bind forward-word          '^[[1;5C' '^[[1;3C'          # Ctrl/Alt-Right
_bind reverse-menu-complete '^[[Z'                       # Shift-Tab
_bind edit-command-line     '^x^e'                       # edit line in $EDITOR
_bind autosuggest-accept    '^ '                         # Ctrl-Space
unfunction _bind

WORDCHARS=${WORDCHARS//\/}              # word motions/^W stop at path separators

# ══════════════════════════════════════════════════════════════════════════════
#  fzf  — Ctrl-R history, Ctrl-T files, Alt-C cd, **<Tab> fuzzy completion
# ══════════════════════════════════════════════════════════════════════════════
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'
if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    _fzf_compgen_path() { fd --hidden --follow --exclude .git . "$1" }
    _fzf_compgen_dir()  { fd --type d --hidden --follow --exclude .git . "$1" }
fi
(( $+commands[bat] )) && \
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"

# fzf ≥ 0.48 ships its own init (same on every OS); older ones: Arch file paths
if ! _cached_init fzf --zsh; then
    for _f in /usr/share/fzf/{key-bindings,completion}.zsh; do
        [[ -r $_f ]] && source $_f
    done
    unset _f
fi

# ══════════════════════════════════════════════════════════════════════════════
#  Aliases
# ══════════════════════════════════════════════════════════════════════════════
if (( $+commands[eza] )); then          # same on macOS and Linux
    # add --icons=auto to these if your terminal uses a Nerd Font
    alias ls='eza -F --group-directories-first'
    alias ll='eza -lF --group-directories-first --git'      # long + git status
    alias la='eza -laF --group-directories-first --git'     # long + hidden
    alias lt='eza -T -L 2 --group-directories-first'        # tree, 2 levels
    alias lta='eza -Ta -L 2 --group-directories-first --git-ignore -I .git'
elif [[ $OSTYPE == darwin* ]]; then
    if (( $+commands[gls] )); then      # GNU ls from `brew install coreutils`
        alias ls='gls --color=auto -hF --group-directories-first'
    else
        alias ls='ls -G -hF'
    fi
else
    alias ls='ls --color=auto -hF --group-directories-first'
fi
[[ $OSTYPE != darwin* ]] && alias open='xdg-open'   # macOS already has `open`
alias vim='nvim'
alias c='clear'
(( $+commands[bat] )) && alias cat='bat'

# ══════════════════════════════════════════════════════════════════════════════
#  Functions
# ══════════════════════════════════════════════════════════════════════════════
fzfp() {
    fzf --preview "bat --style=header,grid --color=always --line-range :500 {}"
}

# ══════════════════════════════════════════════════════════════════════════════
#  Extras
# ══════════════════════════════════════════════════════════════════════════════
# Arch: suggests the package providing a missing command (pacman -S pkgfile && pkgfile -u)
[[ -r /usr/share/doc/pkgfile/command-not-found.zsh ]] && \
    source /usr/share/doc/pkgfile/command-not-found.zsh

# ══════════════════════════════════════════════════════════════════════════════
#  Tool init  (last)
# ══════════════════════════════════════════════════════════════════════════════
_cached_init zoxide init zsh --cmd cd
_cached_init starship init zsh

# Machine-specific settings that shouldn't be shared between your computers
[[ -r ${ZDOTDIR:-$HOME}/.zshrc.local ]] && source ${ZDOTDIR:-$HOME}/.zshrc.local

[[ -n $ZSH_PROFILE ]] && zprof
true    # don't start the first prompt with a failed status
