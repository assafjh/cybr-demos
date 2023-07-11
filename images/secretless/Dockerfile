FROM alpine:latest
LABEL maintainer=AssafHazan

ENV DB_HOST localhost
ENV DB_PORT 5432
ENV DB_NAME vet
ENV TABLE_NAME zoo

RUN  apk update \
  && apk add dumb-init postgresql \
  && mkdir -p /scripts

COPY ./scripts/entry-point.sh /scripts/
COPY ./scripts/query-database.sh /scripts/

WORKDIR /scripts

ENTRYPOINT [ "dumb-init", "/scripts/entry-point.sh" ]
