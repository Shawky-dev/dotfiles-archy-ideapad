# ROS 2
if [ -f /opt/ros/jazzy/setup.zsh ]; then
  source /opt/ros/jazzy/setup.zsh
else
  source /opt/ros/jazzy/setup.bash
fi

# overlay workspace if built
if [ -f /ros2/ws/install/setup.zsh ]; then
  source /ros2/ws/install/setup.zsh
elif [ -f /ros2/ws/install/setup.bash ]; then
  source /ros2/ws/install/setup.bash
fi

### POWERLEVEL10K INSTANT PROMPT ###############################################
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### HOMEBREW INIT ###############################################################
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

### OH MY ZSH ###################################################################
export ZSH="$HOME/.oh-my-zsh"

# Load Powerlevel10k theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# OMZ plugins (translated from your Zinit plugins + snippets)
plugins=(
  git
  sudo
  aws
  kubectl
  kubectx
  archlinux
  command-not-found
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
)

source $ZSH/oh-my-zsh.sh

### ADDITIONAL MANUAL PLUGINS ###################################################

# fzf-tab (OMZ does not include this plugin)
# Make sure it is cloned manually:
# git clone https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
source ~/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh

### COMPLETION INIT #############################################################
autoload -Uz compinit && compinit

### KEYBINDINGS #################################################################
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

### HISTORY CONFIG ##############################################################
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE

HISTDUP=erase
setopt appendhistory sharehistory
setopt hist_ignore_space hist_ignore_all_dups hist_save_no_dups
setopt hist_ignore_dups hist_find_no_dups

### COMPLETION STYLE ############################################################
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# fzf-tab preview settings
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

### ALIASES #####################################################################
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

### INTEGRATIONS ###############################################################
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

### P10K CONFIG #################################################################
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh




ros2-start(){

  # allow container GUI
  xhost +local:docker >/dev/null 2>&1

  if docker inspect ros2 >/dev/null 2>&1; then
      docker start ros2 >/dev/null
      docker exec -it ros2 zsh
  else
    docker run -it \
      --name ros2 \
      --add-host archy-ideapad:127.0.1.1 \
      --env DISPLAY=$DISPLAY \
      --env QT_X11_NO_MITSHM=1 \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v $HOME/ros2:/ros2 \
      --device /dev/dri \
      --network host \
      ros2-jazzy-dev
  fi
}

ros2-connect(){
  docker exec -it ros2 zsh
}

ros2-clean(){
  docker rm -f ros2
}