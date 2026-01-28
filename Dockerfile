FROM node:22-slim AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG USERNAME=gemini
ARG UID=1000
ARG GID=1000
ARG GEMINI_CLI_VERSION=latest

RUN sed -i "/^[^:]*:x:${GID}:/d" /etc/group \
    && sed -i "/^[^:]*:x:${UID}:/d" /etc/passwd \
    && echo "${USERNAME}:x:${UID}:${GID}::/home/${USERNAME}:/sbin/nologin" >> /etc/passwd \
    && echo "${USERNAME}:x:${GID}:" >> /etc/group \
    && mkdir -p /home/${USERNAME} \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    curl \
    gnupg \
    jq \
    ripgrep \
    tzdata \
    wget \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11 and pip in a dedicated layer
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3.11-distutils \
    python3-pip \
    ffmpeg \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 || true \
    && ln -sf /usr/bin/pip3 /usr/bin/pip || true \
    && ln -sf /usr/bin/python3.11 /usr/bin/python || true \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g "@google/gemini-cli@${GEMINI_CLI_VERSION}"

USER ${USERNAME}
WORKDIR /work

ENTRYPOINT ["gemini"]
