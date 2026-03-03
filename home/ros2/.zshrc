########################################
# POWERLEVEL10K INSTANT PROMPT
########################################
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

########################################
# ROS 2
########################################
if [ -f /opt/ros/jazzy/setup.zsh ]; then
  source /opt/ros/jazzy/setup.zsh
else
  source /opt/ros/jazzy/setup.bash
fi

# Overlay workspace
[ -f /ros2/ws/install/setup.zsh ] && source /ros2/ws/install/setup.zsh

# ROS2 argcomplete (must be BEFORE OMZ)
autoload -U bashcompinit
bashcompinit
eval "$(register-python-argcomplete ros2)"

########################################
# HOMEBREW (optional)
########################################
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

########################################
# OH MY ZSH
########################################
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  sudo
  aws
  command-not-found
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
)

source $ZSH/oh-my-zsh.sh

########################################
# ADDITIONAL PLUGINS
########################################
source ~/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh

########################################
# KEYBINDINGS
########################################
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

########################################
# HISTORY
########################################
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE

setopt appendhistory sharehistory
setopt hist_ignore_space hist_ignore_all_dups
setopt hist_save_no_dups hist_ignore_dups hist_find_no_dups

########################################
# COMPLETION STYLE
########################################
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# fzf-tab previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

########################################
# ALIASES
########################################
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

########################################
# INTEGRATIONS
########################################
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

########################################
# POWERLEVEL10K CONFIG
########################################
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
[[ -f ~/.config/zsh/.p10k.zsh ]] && source ~/.config/zsh/.p10k.zshs