echo $PATH >~/.path.bak

# where I save my keys info
source $HOME/.envrc

#source aliases
source $HOME/.aliasrc
# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

set -h
# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# amp
export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH=/home/larryck/.opencode/bin:$PATH

export PATH="$PATH:$HOME/.config/composer/vendor/bin"

export PATH="$PATH:$HOME/scripts"
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk

. "$HOME/.local/share/../bin/env"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export GRAALVM_HOME=/home/larryck/.sdkman/candidates/java/current/bin/java
