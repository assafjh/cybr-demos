FROM alpine:latest

# OCI Labels
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Demo application waiting for Conjur Secrets Provider (Push-to-File)"
LABEL org.opencontainers.image.licenses="MIT"

ENV INJECTED_FILES_PATH=/opt/secrets/conjur
ENV RUN_MESSENGER=false
ENV WAIT_TIMEOUT=5

# Install dumb-init and clean up cache to keep image small
RUN apk update \
    && apk add --no-cache dumb-init \
    && mkdir -p /scripts \
    && mkdir -p /opt/secrets/conjur \
    && chown -R 1000:1000 /opt/secrets

# Copy entrypoint and ensure it is executable
COPY ./scripts/entry-point.sh /scripts/
RUN chmod +x /scripts/entry-point.sh

WORKDIR /scripts
USER 1000:1000

# Standard best practice for dumb-init
ENTRYPOINT [ "dumb-init", "--", "/scripts/entry-point.sh" ]