FROM debian:stable-slim AS downloader

ARG TARGETOS TARGETARCH
ARG DOWNLOAD_DIR=/downloads

# add download tools
RUN apt-get update && apt-get install -y curl jq tar

# create and set download directory
RUN mkdir -p ${DOWNLOAD_DIR}

# go (ignore src and test to reduce size)
RUN --mount=type=cache,target=${DOWNLOAD_DIR}/go/src,sharing=locked \
    --mount=type=cache,target=${DOWNLOAD_DIR}/go/test,sharing=locked \
    curl -L https://go.dev/dl/$(curl -s "https://go.dev/dl/?mode=json" \
                                    | jq -r '.[0].version').linux-${TARGETARCH}.tar.gz \
        | tar -C ${DOWNLOAD_DIR} -xz

# starship
RUN --mount=type=cache,target=/tmp \
    curl -sSf https://starship.rs/install.sh | sh -s -- -y

# gosu
RUN curl -Lo ${DOWNLOAD_DIR}/gosu \
    $(curl -sL "https://api.github.com/repos/tianon/gosu/releases/latest" \
          | jq --arg arch ${TARGETARCH} -r '.assets[] | select(.name == ("gosu-" + $arch)) | .browser_download_url') && \
    chmod +x ${DOWNLOAD_DIR}/gosu

# rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
        -y --profile minimal --no-modify-path

# nodejs
RUN --mount=type=cache,target=/tmp \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash && \
    bash -c ". $HOME/.nvm/nvm.sh && \
    nvm install --lts && \
    nvm use --lts && \
    nvm cache clear"

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh -s -- \
        -q --no-modify-path

FROM debian:stable-slim

ARG TARGETOS TARGETARCH
ARG DOWNLOAD_DIR=/downloads

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
COPY --from=downloader ${DOWNLOAD_DIR}/go /usr/local/go

# starship
COPY --from=downloader /usr/local/bin/starship /usr/local/bin/starship

# gosu
COPY --from=downloader ${DOWNLOAD_DIR}/gosu /usr/local/bin/gosu

# create user
ARG USERNAME=player
ARG GROUPNAME=player
RUN groupadd ${GROUPNAME} || true && \
    useradd -g ${GROUPNAME} -m -s /bin/bash ${USERNAME} || true && \
    usermod -aG sudo "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# INSTALL USER-LEVEL TOOLS

USER ${USERNAME}

# rust
COPY --from=downloader --chown=${USERNAME}:${GROUPNAME} /root/.cargo /home/${USERNAME}/.cargo
COPY --from=downloader --chown=${USERNAME}:${GROUPNAME} /root/.rustup /home/${USERNAME}/.rustup

# nodejs
COPY --from=downloader --chown=${USERNAME}:${GROUPNAME} /root/.nvm /home/${USERNAME}/.nvm

# uv (ignore ~/.config/uv/uv-receipt.json)
COPY --from=downloader --chown=${USERNAME}:${GROUPNAME} /root/.local/bin/uv /home/${USERNAME}/.local/bin/uv
COPY --from=downloader --chown=${USERNAME}:${GROUPNAME} /root/.local/bin/uvx /home/${USERNAME}/.local/bin/uvx

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
USER ${USERNAME}
RUN tee -a $HOME/.profile -a $HOME/.bashrc <<"EOF"
export PATH="$HOME/.local/bin:$PATH"

. "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF

# user-level feature config
RUN sed -i "s/#[ \t]*alias /alias /g" $HOME/.bashrc

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
