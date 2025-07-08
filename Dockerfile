FROM debian:stable-slim

ARG TARGETOS TARGETARCH

ARG APT_MIRROR_DOMAIN=mirrors.ustc.edu.cn
ARG PYPI_MIRROR=https://mirrors.ustc.edu.cn/pypi/simple
ARG UV_PYTHON_INSTALL_MIRROR=https://gh-proxy.com/github.com/astral-sh/python-build-standalone/releases/download
ARG GO_PROXY=https://goproxy.io,direct
ARG CRATES_MIRROR=sparse+https://mirrors.ustc.edu.cn/crates.io-index/

# INSTALL ROOT-LEVEL TOOLS

# apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get --no-install-recommends install -y ca-certificates && \
    find /etc/apt -type f -name "*.sources" | xargs -I{} sed -i 's|http://|https://|g' {} && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get --no-install-recommends install -y \
        wget curl git vim sudo jq \
        build-essential cmake \
        python3 python3-pip python3-venv python-is-python3

# go
RUN --mount=type=cache,target=/usr/local/go/src,sharing=locked \
    --mount=type=cache,target=/usr/local/go/test,sharing=locked \
    curl -L https://go.dev/dl/$(curl -s "https://go.dev/dl/?mode=json" \
                                    | jq -r '.[0].version').linux-${TARGETARCH}.tar.gz \
        | sudo tar -C /usr/local -xz

# starship
RUN --mount=type=cache,target=/tmp \
    curl -sSf https://starship.rs/install.sh | sh -s -- -y

# gosu
RUN curl -Lo /usr/local/bin/gosu \
    $(curl -sL "https://api.github.com/repos/tianon/gosu/releases/latest" \
          | jq --arg arch ${TARGETARCH} -r '.assets[] | select(.name == ("gosu-" + $arch)) | .browser_download_url') && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true

# create user
ARG USERNAME=player
ARG GROUPNAME=player
RUN groupadd ${GROUPNAME} || true && \
    useradd -g ${GROUPNAME} -m -s /bin/bash ${USERNAME} || true && \
    usermod -aG sudo "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# INSTALL USER-LEVEL TOOLS

USER player

# rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
        -y --profile minimal --no-modify-path

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh -s -- \
        -q --no-modify-path

# CONFIG

# root-level PATH config
USER root
RUN tee -a /etc/.profile -a /etc/bash.bashrc <<"EOF"
export PATH="/usr/local/go/bin:$PATH"
EOF
RUN tee -a /etc/bash.bashrc <<"EOF"
eval "$(starship init bash)"
EOF

# root-level proxy config
RUN find /etc/apt -type f -name "*.sources" | xargs -I{} sed -i "s/deb.debian.org/$APT_MIRROR_DOMAIN/g" {}
RUN mkdir -p /etc/uv && tee /etc/uv/uv.toml <<EOF
python-install-mirror = "$UV_PYTHON_INSTALL_MIRROR"
[[index]]
url = "$PYPI_MIRROR"
default = true
EOF

# user-level PATH config
USER player
RUN tee -a $HOME/.profile -a $HOME/.bashrc <<"EOF"
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/.cargo/env"
EOF

# user-level proxy config
RUN /usr/local/go/bin/go env -w GOPROXY=$GO_PROXY
RUN pip config set global.index-url $PYPI_MIRROR
RUN tee $HOME/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = "ustc"
[source.ustc]
registry = "$CRATES_MIRROR"
EOF

# enter entrypoint as root
USER root

# add entrypoint.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# default command
ENV WORKSPACE=/playground
CMD ["/bin/bash"]
