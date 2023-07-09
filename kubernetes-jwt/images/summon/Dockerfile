FROM alpine:latest
LABEL maintainer=AssafHazan

RUN  apk update \
  && apk add curl tar dumb-init \
  && mkdir -p /usr/local/lib/summon \
  && mkdir -p /scripts \
  && cd /usr/local/bin \
  && curl -sSL https://github.com/cyberark/summon/releases/download/v0.9.6/summon-linux-amd64.tar.gz \
      | tar xz \
  && cd /usr/local/lib/summon \
  && curl -sSL https://github.com/cyberark/summon-conjur/releases/download/v0.7.1/summon-conjur-linux-amd64.tar.gz \
      | tar xz

# Fix for summon-conjur dynamically linking to libc
RUN  mkdir -p /lib64 \
  && ln -fs /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2;

WORKDIR /scripts

COPY ./scripts/secrets.yml /scripts/
COPY ./scripts/demo-consumer.sh /scripts/
COPY ./scripts/entry-point.sh /scripts/

ENTRYPOINT [ "dumb-init", "summon", "--provider", "summon-conjur", "-f", "/scripts/secrets.yml", "/scripts/entry-point.sh" ]
