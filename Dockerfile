FROM node:22-slim AS builder

ARG USERNAME=gemini
ARG UID=1000
ARG GID=1000
ARG GEMINI_CLI_VERSION=latest

RUN sed -i "/^[^:]*:x:${GID}:/d" /etc/group \
    && sed -i "/^[^:]*:x:${UID}:/d" /etc/passwd \
    && echo "${USERNAME}:x:${UID}:${GID}::/home/${USERNAME}:/sbin/nologin" >> /etc/passwd \
    && echo "${USERNAME}:x:${GID}:" >> /etc/group \
    && mkdir -p /home/${USERNAME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g "@google/gemini-cli@${GEMINI_CLI_VERSION}"

USER ${USERNAME}
WORKDIR /work

ENTRYPOINT ["gemini"]
