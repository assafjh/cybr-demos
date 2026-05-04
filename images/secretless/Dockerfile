FROM alpine:latest
# OCI Labels
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Demo application using Secretless Broker to connect to PostgreSQL"
LABEL org.opencontainers.image.licenses="MIT"

ENV DB_HOST localhost
ENV DB_PORT 5432
ENV DB_NAME vet
ENV TABLE_NAME zoo

RUN  apk update \
  && apk add --no-cache dumb-init postgresql \
  && mkdir -p /scripts

COPY ./scripts/entry-point.sh /scripts/
COPY ./scripts/query-database.sh /scripts/

RUN chmod +x /scripts/*.sh

WORKDIR /scripts
USER 1000:1000

ENTRYPOINT [ "dumb-init", "--", "/scripts/entry-point.sh" ]
