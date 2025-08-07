FROM debian:12-slim AS os-prep

ARG USERNAME=gemini
ARG UID=1000
ARG GID=1000

COPY --from=gcr.io/distroless/nodejs20-debian12:nonroot /etc/passwd /etc/group /tmp/

RUN echo "${USERNAME}:x:${UID}:${GID}::/home/${USERNAME}:/sbin/nologin" >> /tmp/passwd \
    && echo "${USERNAME}:x:${GID}:" >> /tmp/group \
    && mkdir -p /tmp/home/${USERNAME}

FROM node:20-slim AS builder

ARG GEMINI_CLI_VERSION=latest

RUN npm install -g "@google/gemini-cli@${GEMINI_CLI_VERSION}"

FROM gcr.io/distroless/nodejs20-debian12:nonroot

ARG USERNAME=gemini
ARG UID=1000
ARG GID=1000

COPY --from=os-prep --chown=0:0 --chmod=0644 /tmp/passwd /etc/passwd
COPY --from=os-prep --chown=0:0 --chmod=0644 /tmp/group /etc/group
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=os-prep --chown=${UID}:${GID} --chmod=0700 /tmp/home/${USERNAME} /home/${USERNAME}

USER ${USERNAME}
WORKDIR /work

ENTRYPOINT ["/nodejs/bin/node", "/usr/local/lib/node_modules/@google/gemini-cli/dist/index.js"]
