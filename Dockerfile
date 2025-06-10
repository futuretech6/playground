FROM debian:latest

ARG TARGETOS TARGETARCH
ARG UID GID

RUN find /etc/apt -type f -name "*.sources" | xargs -I{} sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' {}
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get --no-install-recommends install -y \
        wget curl git vim sudo \
        zsh \
        python3 python3-pip python3-venv python-is-python3

RUN groupadd -g "$GID" player || true
RUN useradd -u "$UID" -g "$GID" -m -s /bin/bash player
RUN usermod -aG sudo player
RUN echo 'player ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER player
WORKDIR /home/player

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

