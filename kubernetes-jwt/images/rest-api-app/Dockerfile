FROM alpine:latest
LABEL maintainer=AssafHazan

ENV CONJUR_VARIABLE_PATH data/kubernetes/applications/safe/secret1

RUN  apk update \
  && apk add curl dumb-init \
  && mkdir -p /scripts

COPY ./scripts/entry-point.sh /scripts/
COPY ./scripts/retrieve.sh /scripts/

WORKDIR /scripts

ENTRYPOINT [ "dumb-init", "/scripts/entry-point.sh" ]