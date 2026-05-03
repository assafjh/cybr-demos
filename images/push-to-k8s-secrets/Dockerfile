FROM alpine:latest

# OCI Labels
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Demo application for Conjur Kubernetes Secrets injection (Env Vars)"
LABEL org.opencontainers.image.licenses="MIT"

# Install dumb-init
RUN apk update \
    && apk add --no-cache dumb-init \
    && mkdir -p /scripts

COPY ./scripts/entry-point.sh /scripts/
RUN chmod +x /scripts/entry-point.sh

WORKDIR /scripts

ENTRYPOINT [ "dumb-init", "--", "/scripts/entry-point.sh" ]