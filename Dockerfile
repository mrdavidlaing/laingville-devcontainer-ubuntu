# syntax=docker/dockerfile:1.7-labs
#
# Ubuntu devcontainers for Laingville.
#
# Notes:
# - We intentionally do NOT include Nix.
# - We rely STRICTLY on upstream Ubuntu packages to improve security posture and reduce SBOM complexity.
# - Versions are those provided by Ubuntu 24.04 (Noble).
#
# If you want stronger reproducibility, set UBUNTU_IMAGE to a pinned digest.
# Ideally use a multi-arch manifest-list digest.

ARG UBUNTU_IMAGE=ubuntu:24.04

############################
# base: shared OS + common tools
############################
FROM ${UBUNTU_IMAGE} AS base
ARG TARGETARCH
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
      jq ripgrep fd-find bat fzf \
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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --no-install-recommends \
      shellcheck \
      just \
      starship \
      shfmt \
 && rm -rf /var/lib/apt/lists/*

# shellspec is not in Ubuntu 24.04 repos, so it is omitted.

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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --no-install-recommends \
      nodejs npm \
 && rm -rf /var/lib/apt/lists/*

RUN node --version \
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
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
 && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
 && mkdir -p /workspace \
 && chown -R "${USERNAME}:${USER_GID}" /workspace

USER ${USERNAME}
WORKDIR /workspace
CMD ["bash"]
