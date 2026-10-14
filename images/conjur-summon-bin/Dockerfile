# Carrier image for the conjur-injector "summon" mode.
# It only holds the summon + summon-conjur binaries; the injector runs it as an
# init container that copies them into a shared in-memory volume. App images stay untouched.
FROM alpine:3.20 AS fetch

ARG SUMMON_VERSION=v0.13.1
ARG SUMMON_CONJUR_VERSION=v0.9.3

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Both release binaries are statically linked for linux/amd64, so they run inside any app image
# (alpine, debian, distroless). summon-conjur publishes no linux/arm64 build.
RUN apk add --no-cache curl tar \
  && mkdir -p /out \
  && curl -fsSL "https://github.com/cyberark/summon/releases/download/${SUMMON_VERSION}/summon-linux-amd64.tar.gz" | tar xz -C /out \
  && curl -fsSL "https://github.com/cyberark/summon-conjur/releases/download/${SUMMON_CONJUR_VERSION}/summon-conjur-linux-amd64.tar.gz" | tar xz -C /out \
  && chmod 0755 /out/summon /out/summon-conjur

FROM busybox:1.36-musl

LABEL org.opencontainers.image.title="Conjur Summon binaries carrier"
LABEL org.opencontainers.image.authors="Assaf Hazan"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Holds static summon + summon-conjur binaries for injection by the conjur-injector mutating webhook"
LABEL org.opencontainers.image.licenses="MIT"

COPY --from=fetch /out/summon /out/summon-conjur /summon/
USER 65532:65532
# The injector sets the real command; this default just shows what is inside.
CMD ["ls", "-l", "/summon"]
