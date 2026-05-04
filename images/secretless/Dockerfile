FROM alpine:latest

# OCI Labels
LABEL org.opencontainers.image.title="Secretless Broker PostgreSQL Demo"
LABEL org.opencontainers.image.authors="Assaf Hazan"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Demo application demonstrating Secretless Broker for secure PostgreSQL connectivity without embedded credentials"
LABEL org.opencontainers.image.licenses="MIT"

ENV DB_HOST localhost
ENV DB_PORT 5432
ENV DB_NAME postgres
ENV TABLE_NAME customers

RUN apk add --no-cache dumb-init postgresql \
  && mkdir -p /scripts \
  && adduser -D -u 1000 appuser

COPY ./scripts/entry-point.sh /scripts/
COPY ./scripts/query-database.sh /scripts/

RUN chmod +x /scripts/*.sh

WORKDIR /scripts
USER 1000:1000

ENTRYPOINT [ "dumb-init", "--", "/scripts/entry-point.sh" ]
