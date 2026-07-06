# ============================================================================
# HISTORY
# =============================================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS


# =========================================
# Shell behaviour
# =========================================
#

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT # sort file10 after file9, not after file1

#==================================================================
# Smart directory navigation
# ========================================================
#
eval "$(zoxide init zsh)"

# Where my keys
source "$HOME/.envrc"

# opencode
export PATH=/home/larryck/.opencode/bin:$PATH

export PATH="$PATH:$HOME/.config/composer/vendor/bin"

export PATH="$PATH:$HOME/scripts"

. "$HOME/.local/share/../bin/env"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

export JAVA_HOME=/home/larryck/.sdkman/candidates/java/current/bin/java
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export GRAALVM_HOME=/home/larryck/.sdkman/candidates/java/current/bin/java



#==================================================================
# Completion
#========================================================

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

#Make completion case-insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# =========================================================
# Fuzzy finder
# =========================================================

# Arch
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# =========================================================
# Modular Config Files
# =========================================================

# fzf configuration
source "$ZDOTDIR/fzf.zsh"

# Aliases
source "$ZDOTDIR/aliases.zsh"

# Custom keybindings
source "$ZDOTDIR/bindings.zsh"

# Plugins and plugin manager
source "$ZDOTDIR/plugins.zsh"

# Prompt/theme
source "$ZDOTDIR/prompt.zsh"
