FROM alpine:latest
LABEL maintainer=AssafHazan

RUN  apk update \
  && apk add curl tar \
  && mkdir -p /usr/local/lib/summon \
  && mkdir -p /etc/summon/config \
  && mkdir -p /etc/summon/demo_app \
  && cd /usr/local/bin \
  && curl -sSL https://github.com/cyberark/summon/releases/download/v0.9.6/summon-linux-amd64.tar.gz \
      | tar xz \
  && cd /usr/local/lib/summon \
  && curl -sSL https://github.com/cyberark/summon-conjur/releases/download/v0.7.1/summon-conjur-linux-amd64.tar.gz \
      | tar xz

# Fix for summon-conjur dynamically linking to libc
RUN  mkdir -p /lib64 \
  && ln -fs /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2;

# Will be mounted - no need to add hardcoded scripts
#COPY config /etc/summon/config
#COPY demo_app /etc/summon/demo_app

ENTRYPOINT [ "summon", "--provider", "summon-conjur", "-f", "/etc/summon/config/secrets.yml", "/etc/summon/demo_app/demo_consumer.sh" ]
