FROM alpine:latest
# OCI Labels
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="REST API Authenticator Client demo application for Conjur authentication"
LABEL org.opencontainers.image.licenses="MIT"

ENV CONJUR_VARIABLE_PATH data/kubernetes/applications/safe/secret1

RUN  apk update \
  && apk add --no-cache curl dumb-init \
  && mkdir -p /scripts

COPY ./scripts/entry-point.sh /scripts/
COPY ./scripts/retrieve.sh /scripts/

RUN chmod +x /scripts/*.sh

WORKDIR /scripts
USER 1000:1000

ENTRYPOINT [ "dumb-init", "--", "/scripts/entry-point.sh" ]
