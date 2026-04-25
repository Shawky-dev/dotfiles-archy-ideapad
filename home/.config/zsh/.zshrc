export DISABLE_AUTO_TITLE='true'
fastfetch
### POWERLEVEL10K INSTANT PROMPT ###############################################
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### HOMEBREW INIT ###############################################################
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

### OH MY ZSH ###################################################################
if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
elif [[ -f "/usr/share/oh-my-zsh/oh-my-zsh.sh" ]]; then
  export ZSH="/usr/share/oh-my-zsh"
else
  export ZSH="$HOME/.oh-my-zsh"
fi

if [[ "$ZSH" == "/usr/share/oh-my-zsh" && -d "$HOME/.oh-my-zsh/custom" ]]; then
  export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
fi

# Load Powerlevel10k theme
if [[ -f "${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
elif [[ -f "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  ZSH_THEME=""
  source "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme"
else
  ZSH_THEME=""
fi

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
)

if [[ -d /usr/share/zsh/site-functions ]]; then
  fpath=(/usr/share/zsh/site-functions $fpath)
fi

source "$ZSH/oh-my-zsh.sh"

### ADDITIONAL MANUAL PLUGINS ###################################################

# fzf-tab (OMZ does not include this plugin)
# Make sure it is cloned manually:
# git clone https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
if [[ -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

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
alias clipboard='xclip -selection clipboard'

alias vncon='x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd -rfbport 5900 & disown'
alias vncoff='pkill -f x11vnc'
alias nukedocker='~/scripts/nuke_docker.sh'

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
