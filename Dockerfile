# syntax=docker/dockerfile:1.7-labs
#
# Ubuntu devcontainers for Laingville.
#
# Notes:
# - We intentionally do NOT include Nix.
# - Node is installed from upstream tarballs with checksum verification.
# - npm is pinned to 11.x to match the Node invariant tests from laingville/infra.
#
# If you want stronger reproducibility, set UBUNTU_IMAGE to a pinned digest.
# Ideally use a multi-arch manifest-list digest.

ARG UBUNTU_IMAGE=ubuntu:24.04

############################
# base: shared OS + common tools
############################
FROM ${UBUNTU_IMAGE} AS base
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg locales tzdata \
      bash coreutils findutils grep sed gawk \
      tar gzip xz-utils bzip2 unzip zip \
      git openssh-client \
      sudo \
      jq ripgrep fd-find fzf bat \
      less procps \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

# Ubuntu binary name quirks: bat -> batcat, fd -> fdfind
RUN ln -sf /usr/bin/batcat /usr/local/bin/bat || true \
 && ln -sf /usr/bin/fdfind /usr/local/bin/fd || true

########################################
# bashdev: laingville bash toolchain
########################################
FROM base AS bashdev
ARG TARGETARCH
ARG JUST_VERSION=1.40.0
ARG STARSHIP_VERSION=1.22.1
ARG SHFMT_VERSION=3.10.0
ARG SHELLSPEC_VERSION=0.28.1

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --no-install-recommends \
      shellcheck \
 && rm -rf /var/lib/apt/lists/*

# just (static)
RUN case "${TARGETARCH}" in \
      amd64) arch="x86_64" ;; \
      arm64) arch="aarch64" ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSLo /tmp/just.tgz \
      "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${arch}-unknown-linux-musl.tar.gz" \
 && tar -C /usr/local/bin -xzf /tmp/just.tgz just \
 && rm -f /tmp/just.tgz

# starship (static)
RUN case "${TARGETARCH}" in \
      amd64) arch="x86_64" ;; \
      arm64) arch="aarch64" ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSLo /tmp/starship.tgz \
      "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${arch}-unknown-linux-musl.tar.gz" \
 && tar -C /usr/local/bin -xzf /tmp/starship.tgz starship \
 && rm -f /tmp/starship.tgz

# shfmt
RUN curl -fsSLo /usr/local/bin/shfmt \
      "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${TARGETARCH}" \
 && chmod +x /usr/local/bin/shfmt

# shellspec (git checkout of a tagged release)
RUN git clone --depth 1 --branch "${SHELLSPEC_VERSION}" \
      https://github.com/shellspec/shellspec.git /opt/shellspec \
 && ln -sf /opt/shellspec/shellspec /usr/local/bin/shellspec

########################################
# python: runtime and devcontainer
########################################
FROM base AS python
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv \
 && rm -rf /var/lib/apt/lists/*

FROM python AS pythondev
# Keep minimal for now.

########################################
# node: runtime and devcontainer
########################################
FROM base AS node
ARG TARGETARCH
ARG NODE_VERSION=22.11.0
ARG NPM_VERSION=11.6.4

# Install Node from upstream tarball with checksum verification
RUN case "${TARGETARCH}" in \
      amd64) node_arch="x64" ;; \
      arm64) node_arch="arm64" ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && cd /tmp \
 && curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" \
 && curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" \
 && grep " node-v${NODE_VERSION}-linux-${node_arch}\\.tar\\.xz$" SHASUMS256.txt | sha256sum -c - \
 && tar -C /usr/local --strip-components=1 -xJf "node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" \
 && rm -f "node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" SHASUMS256.txt

RUN npm install -g "npm@${NPM_VERSION}" \
 && node --version \
 && npm --version

FROM node AS nodedev
# Node devcontainer supports node-gyp setup; the test suite exercises this lightly.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

########################################
# common devcontainer user wiring
########################################
FROM bashdev AS laingville-devcontainer
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

RUN if ! getent group "${USER_GID}" > /dev/null 2>&1; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi \
 && if ! id -u "${USERNAME}" > /dev/null 2>&1; then \
      if getent passwd "${USER_UID}" > /dev/null 2>&1; then \
        useradd --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      fi; \
    fi \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
 && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
 && mkdir -p /workspace \
 && chown -R "${USERNAME}:${USER_GID}" /workspace \
 && install -d -o "${USERNAME}" -g "${USER_GID}" "/home/${USERNAME}/.config" \
 && printf '%s\n' \
      'eval "$(starship init bash)"' \
    > "/home/${USERNAME}/.bashrc" \
 && chown "${USERNAME}:${USER_GID}" "/home/${USERNAME}/.bashrc"

USER ${USERNAME}
WORKDIR /workspace
CMD ["bash"]

FROM pythondev AS example-python-devcontainer
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN if ! getent group "${USER_GID}" > /dev/null 2>&1; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi \
 && if ! id -u "${USERNAME}" > /dev/null 2>&1; then \
      if getent passwd "${USER_UID}" > /dev/null 2>&1; then \
        useradd --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      fi; \
    fi \
 && mkdir -p /workspace \
 && chown -R "${USERNAME}:${USER_GID}" /workspace
USER ${USERNAME}
WORKDIR /workspace
CMD ["bash"]

FROM python AS example-python-runtime
ARG USERNAME=app
ARG USER_UID=1000
ARG USER_GID=1000
RUN if ! getent group "${USER_GID}" > /dev/null 2>&1; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi \
 && if ! id -u "${USERNAME}" > /dev/null 2>&1; then \
      if getent passwd "${USER_UID}" > /dev/null 2>&1; then \
        useradd --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      fi; \
    fi \
 && mkdir -p /app \
 && chown -R "${USERNAME}:${USER_GID}" /app
USER ${USERNAME}
WORKDIR /app
CMD ["python3", "--version"]

FROM nodedev AS example-node-devcontainer
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN if ! getent group "${USER_GID}" > /dev/null 2>&1; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi \
 && if ! id -u "${USERNAME}" > /dev/null 2>&1; then \
      if getent passwd "${USER_UID}" > /dev/null 2>&1; then \
        useradd --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      fi; \
    fi \
 && mkdir -p /workspace \
 && chown -R "${USERNAME}:${USER_GID}" /workspace
USER ${USERNAME}
WORKDIR /workspace
CMD ["bash"]

FROM node AS example-node-runtime
ARG USERNAME=app
ARG USER_UID=1000
ARG USER_GID=1000
RUN if ! getent group "${USER_GID}" > /dev/null 2>&1; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi \
 && if ! id -u "${USERNAME}" > /dev/null 2>&1; then \
      if getent passwd "${USER_UID}" > /dev/null 2>&1; then \
        useradd --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
      fi; \
    fi \
 && mkdir -p /app \
 && chown -R "${USERNAME}:${USER_GID}" /app
USER ${USERNAME}
WORKDIR /app
CMD ["node", "--version"]
