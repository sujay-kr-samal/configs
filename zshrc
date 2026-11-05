# ---------- Oh My Zsh ----------
export ZSH="$HOME/.oh-my-zsh"

# prompt is handled by starship, so no oh-my-zsh theme
ZSH_THEME=""

# syntax-highlighting must stay last
plugins=(
    git
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ---------- Autosuggestions (ghost text) ----------
# grey ghost text that completes from history, accept with Right arrow or Ctrl+Space
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept

# ---------- History ----------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY

# ---------- PATH ----------
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---------- Aliases ----------
alias ls='ls --color=auto'
alias ll='ls -lah'
alias ..='cd ..'

# ---------- Starship prompt (keep at the end) ----------
eval "$(starship init zsh)"
