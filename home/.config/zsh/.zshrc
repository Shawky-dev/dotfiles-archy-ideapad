export DISABLE_AUTO_TITLE='true'
fastfetch

### HOMEBREW INIT ###############################################################
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

### COMPLETION INIT #############################################################
if [[ -d /usr/share/zsh/site-functions ]]; then
  fpath=(/usr/share/zsh/site-functions $fpath)
fi

# Keep completion dumps in the cache, not in $ZDOTDIR
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${ZSH_COMPDUMP:h}"
autoload -Uz compinit && compinit -d "$ZSH_COMPDUMP"

### PLUGINS #####################################################################
# Installed with: yay -S zsh-autosuggestions zsh-syntax-highlighting fzf-tab-git
# Order matters: fzf-tab after compinit, syntax-highlighting last.
for plugin in \
  /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.plugin.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/doc/pkgfile/command-not-found.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  [[ -f "$plugin" ]] && source "$plugin"
done
unset plugin

### KEYBINDINGS #################################################################
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# Keys Oh My Zsh used to bind for us
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey '^[[A' up-line-or-beginning-search     # Up: search history by what's typed
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search   # Down
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line               # Home
bindkey '^[OH' beginning-of-line
bindkey '^[[F' end-of-line                     # End
bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char                    # Delete
bindkey '^[[1;5C' forward-word                 # Ctrl+Right
bindkey '^[[1;5D' backward-word                # Ctrl+Left
bindkey '^H' backward-kill-word                # Ctrl+Backspace
bindkey '^[[3;5~' kill-word                    # Ctrl+Delete
bindkey '^[[Z' reverse-menu-complete           # Shift+Tab
bindkey '^x^e' edit-command-line               # Ctrl+X Ctrl+E: edit line in $EDITOR

### SHELL OPTIONS ###############################################################
setopt interactive_comments      # allow "# comments" on the command line
setopt auto_cd                   # type a folder name to cd into it
setopt auto_pushd pushd_ignore_dups pushd_minus   # cd -<TAB> lists recent folders
setopt complete_in_word always_to_end
setopt long_list_jobs
unsetopt flow_control            # free up Ctrl+S / Ctrl+Q

# Press Esc twice to add/remove "sudo" at the start of the line
sudo-command-line() {
  [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
  if [[ $BUFFER == sudo\ * ]]; then
    LBUFFER="${LBUFFER#sudo }"
  else
    LBUFFER="sudo $LBUFFER"
  fi
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line

### HISTORY CONFIG ##############################################################
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE

HISTDUP=erase
setopt appendhistory sharehistory
setopt hist_ignore_space hist_ignore_all_dups hist_save_no_dups
setopt hist_ignore_dups hist_find_no_dups
setopt extended_history hist_verify    # timestamps; show !! expansions before running

### COMPLETION STYLE ############################################################
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' special-dirs true     # complete . and ..
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"

# fzf-tab preview settings
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

### ALIASES #####################################################################
alias ls='ls --color'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias clipboard='xclip -selection clipboard'

alias vncon='x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd -rfbport 5900 & disown'
alias vncoff='pkill -f x11vnc'
alias nukedocker='~/scripts/system/docker-nuke.sh'

### INTEGRATIONS ###############################################################
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

### PROMPT ######################################################################
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

### ROS2 ########################################################################
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
