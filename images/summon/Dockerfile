FROM alpine:latest
# OCI Labels
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Demo application using Summon for secret injection"
LABEL org.opencontainers.image.licenses="MIT"

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache curl tar dumb-init \
  && mkdir -p /usr/local/lib/summon \
  && mkdir -p /scripts \
  && curl -sSL https://github.com/cyberark/summon/releases/download/v0.11.0/summon-linux-amd64.tar.gz \
      | tar xz -C /usr/local/bin \
  && curl -sSL https://github.com/cyberark/summon-conjur/releases/download/v0.9.2/summon-conjur-linux-amd64.tar.gz \
      | tar xz -C /usr/local/lib/summon

# Fix for summon-conjur dynamically linking to libc
RUN  mkdir -p /lib64 \
  && ln -fs /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2;

COPY ./scripts/secrets.yml /scripts/
COPY ./scripts/demo-consumer.sh /scripts/
COPY ./scripts/entry-point.sh /scripts/

RUN chmod +x /scripts/*.sh

WORKDIR /scripts
USER 1000:1000

ENTRYPOINT [ "dumb-init", "--", "summon", "--provider", "summon-conjur", "-f", "/scripts/secrets.yml", "/scripts/entry-point.sh" ]
