FROM osrf/ros:jazzy-desktop-full

RUN apt update && apt install -y \
    zsh git curl wget \
    zoxide \
    python3-argcomplete \
    ros-jazzy-turtlebot3* \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-sim \
 && rm -rf /var/lib/apt/lists/*

ENV TURTLEBOT3_MODEL=burger

# fzf (latest)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf \
 && /root/.fzf/install --all \
 && ln -s /root/.fzf/bin/fzf /usr/local/bin/fzf

# oh-my-zsh
RUN sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
 && git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
 && git clone https://github.com/Aloxaf/fzf-tab \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/fzf-tab \
 && git clone https://github.com/zsh-users/zsh-completions \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-completions

# powerlevel10k
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/themes/powerlevel10k

COPY .zshrc /root/.zshrc

CMD ["/bin/zsh"]