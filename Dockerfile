FROM ubuntu:latest

ARG TARGETOS TARGETARCH

RUN apt-get update
RUN apt-get install -y wget curl git vim sudo

# create user
RUN useradd -m player
RUN echo 'player ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER player
WORKDIR /home/player

# omz
RUN sudo apt-get install -y zsh
RUN sudo chsh player --shell $(which zsh)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN zsh
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN sed -i "s/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/" ~/.zshrc
RUN sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="ys"/' ~/.zshrc
RUN echo "source ~/.profile" >> ~/.zshrc
RUN echo "zstyle ':omz:update' mode disabled" >> ~/.zshrc

# rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN wget -O ~/.cargo/config.toml https://raw.githubusercontent.com/futuretech6/dotfiles/master/rust/config.toml

# python
RUN sudo apt-get install -y python3 python3-pip python-is-python3
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
RUN echo "[global]\nbreak-system-packages = true" > ~/.config/pip/pip.conf

# node
RUN sudo apt-get install -y npm
RUN sudo npm install -g n
RUN sudo n lts
RUN hash -r

# misc
RUN wget -O ~/.vimrc https://raw.githubusercontent.com/futuretech6/dotfiles/master/vim/.vimrc

ENTRYPOINT /usr/bin/zsh
