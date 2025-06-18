FROM debian:latest

ARG TARGETOS TARGETARCH

# INSTALL ROOT-LEVEL TOOLS

# apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get --no-install-recommends install -y ca-certificates && \
    find /etc/apt -type f -name "*.sources" | xargs -I{} sed -i 's|http://|https://|g' {} && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get --no-install-recommends install -y \
        wget curl git vim sudo \
        build-essential cmake \
        python3 python3-pip python3-venv python-is-python3

# go
ARG GO_VERSION=1.23.10
RUN --mount=type=cache,target=/usr/local/go/src,sharing=locked \
    --mount=type=cache,target=/usr/local/go/test,sharing=locked \
    curl -L "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
        | sudo tar -C /usr/local -xz

# starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# gosu
ARG GOSU_VERSION=1.14
RUN curl -Lo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${TARGETARCH}" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true

# create user
RUN groupadd player
RUN useradd -g player -m -s /bin/bash player
RUN usermod -aG sudo player
RUN echo 'player ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# set apt mirrors (for local use only, no need for build time)
RUN find /etc/apt -type f -name "*.sources" | xargs -I{} sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' {}

# INSTALL USER-LEVEL TOOLS

USER player
WORKDIR /home/player

# rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
        -y --profile minimal
RUN tee $HOME/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'ustc'
[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
EOF

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh -s -- -q

# PATH config
RUN tee -a $HOME/.profile -a $HOME/.bashrc <<"EOF"
. "$HOME/.cargo/env"
export PATH=$PATH:/usr/local/go/bin
EOF
RUN tee -a $HOME/.bashrc <<"EOF"
eval "$(starship init bash)"
EOF

# proxy config
RUN /usr/local/go/bin/go env -w GOPROXY=https://goproxy.io,direct
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# enter entrypoint as root
USER root

# add entrypoint.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# default command
ENV WORKSPACE=/playground
WORKDIR $WORKSPACE
CMD ["/bin/bash"]
