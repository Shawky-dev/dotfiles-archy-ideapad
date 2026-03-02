FROM osrf/ros:jazzy-desktop-full

# install required packages
RUN apt update && apt install -y \
    zsh git curl wget \
    fzf \
    zoxide \
    ros-jazzy-turtlebot3* \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-sim \
 && rm -rf /var/lib/apt/lists/*

ENV TURTLEBOT3_MODEL=burger

# install oh-my-zsh non-interactive
RUN sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# install plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
 && git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
 && git clone https://github.com/Aloxaf/fzf-tab \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/fzf-tab \
 && git clone https://github.com/zsh-users/zsh-completions \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-completions

# install powerlevel10k theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/themes/powerlevel10k

# copy your zsh config
COPY .zshrc /root/.zshrc

# use zsh as default shell
CMD ["/bin/zsh"]