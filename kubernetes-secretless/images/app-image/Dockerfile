FROM alpine:latest
LABEL maintainer=AssafHazan

ENV DB_HOST localhost
ENV DB_PORT 5432
ENV DB_NAME vet
ENV TABLE_NAME zoo

RUN  apk update \
  && apk add postgresql \
  && mkdir -p /scripts

COPY entry_point.sh /scripts/
COPY query_database.sh /scripts/

WORKDIR /scripts

ENTRYPOINT [ "/scripts/entry_point.sh" ]
