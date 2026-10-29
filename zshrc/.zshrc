# ══════════════════════════════════════════════════════════════════════════════
#  PATH  — first, so everything below can find binaries in ~/.local/bin
# ══════════════════════════════════════════════════════════════════════════════
export PATH="$HOME/.local/bin:$PATH"

export EDITOR='nvim'
export VISUAL='nvim'

setopt extended_glob
setopt interactive_comments

# ══════════════════════════════════════════════════════════════════════════════
#  Zinit bootstrap
# ══════════════════════════════════════════════════════════════════════════════
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ══════════════════════════════════════════════════════════════════════════════
#  Plugins that only ADD completion definitions  (ORDER: before compinit)
# ══════════════════════════════════════════════════════════════════════════════
zinit light zsh-users/zsh-completions

# ── Snippets: these call compdef, which zinit stashes until cdreplay ──────────
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux

# ══════════════════════════════════════════════════════════════════════════════
#  Completion system  (ORDER: after the above, before fzf-tab)
# ══════════════════════════════════════════════════════════════════════════════
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(N.mh+24) ]]; then
    compinit          # dump is >24h old → full security check
else
    compinit -C       # fresh enough → skip the check
fi

zinit cdreplay -q     # replay the compdefs the snippets registered earlier

# ══════════════════════════════════════════════════════════════════════════════
#  Widget-wrapping plugins
# ══════════════════════════════════════════════════════════════════════════════
zinit light Aloxaf/fzf-tab          # eager: needs compinit, wraps the tab widget

zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

# ══════════════════════════════════════════════════════════════════════════════
#  Completion styling
# ══════════════════════════════════════════════════════════════════════════════
eval "$(dircolors -b)"

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' menu no
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# fzf-tab
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*'           fzf-preview 'ls --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*'   fzf-preview 'ls --color=always $realpath'

# ══════════════════════════════════════════════════════════════════════════════
#  History
# ══════════════════════════════════════════════════════════════════════════════
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt extended_history
setopt appendhistory
setopt sharehistory
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

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^p'   up-line-or-beginning-search
bindkey '^n'   down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search      # Up arrow
bindkey '^[[B' down-line-or-beginning-search    # Down arrow

WORDCHARS='${WORDCHARS/\/}'                     # ^W stops at path separators

# fzf's own bindings: ^R history, ^T files, M-c cd
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh   ]] && source /usr/share/fzf/completion.zsh

# ══════════════════════════════════════════════════════════════════════════════
#  Aliases
# ══════════════════════════════════════════════════════════════════════════════
alias ls='ls --color=auto -hF --group-directories-first'
alias vim='nvim'
alias c='clear'
alias open='xdg-open'
alias cat='bat'

# ══════════════════════════════════════════════════════════════════════════════
#  Functions
# ══════════════════════════════════════════════════════════════════════════════
fzfp() {
    fzf --preview "bat --style=header,grid --color=always --line-range :500 {}" || return
}

# ══════════════════════════════════════════════════════════════════════════════
#  Extras
# ══════════════════════════════════════════════════════════════════════════════
# Suggests the package providing a missing command (needs: pacman -S pkgfile && pkgfile -u)
[[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]] && \
    source /usr/share/doc/pkgfile/command-not-found.zsh

# ══════════════════════════════════════════════════════════════════════════════
#  Tool init  (last)
# ══════════════════════════════════════════════════════════════════════════════
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

export PATH="$HOME/.local/bin:$PATH"
