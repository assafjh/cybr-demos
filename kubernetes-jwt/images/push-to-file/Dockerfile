FROM alpine:latest
LABEL maintainer=AssafHazan

ENV INJECTED_FILES_PATH /opt/secrets/conjur

RUN  apk update \
  && apk add dumb-init \
  && mkdir -p /scripts

COPY ./scripts/entry-point.sh /scripts/

WORKDIR /scripts

ENTRYPOINT [ "dumb-init", "/scripts/entry-point.sh" ]
