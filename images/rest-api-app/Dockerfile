FROM alpine:latest

# OCI Labels
LABEL org.opencontainers.image.title="Conjur REST API Demo (Secrets Retrieval)"
LABEL org.opencontainers.image.authors="Assaf Hazan"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="REST API demo application for CyberArk Conjur secret retrieval supporting both pre-authenticated sidecar mode and self-authenticated JWT-based mode"
LABEL org.opencontainers.image.licenses="MIT"

# Auth mode:
#   "pre-authenticated" — reads access-token from /run/conjur/access-token
#                         (injected by a Conjur authenticator sidecar, e.g. authn-k8s with certificate or authn-jwt)
#                         The app makes 1 REST call: GET secret.
#
#   "self-authenticated" — reads the pod's K8s service-account JWT and authenticates directly to Conjur (authn-jwt).
#                          The app makes 2 REST calls: POST authenticate + GET secret.
ENV AUTH_MODE=pre-authenticated

ENV CONJUR_VARIABLE_PATH=data/kubernetes/applications/safe/secret1

RUN apk add --no-cache curl dumb-init \
  && mkdir -p /scripts

COPY ./scripts/entry-point.sh /scripts/
COPY ./scripts/retrieve.sh /scripts/

RUN chmod +x /scripts/*.sh

WORKDIR /scripts
USER 1000:1000

ENTRYPOINT [ "dumb-init", "--", "/scripts/entry-point.sh" ]
