FROM postgres:11.2-alpine
LABEL maintainer=AssafHazan

ENV POSTGRES_USER admin
ENV POSTGRES_PASSWORD 123456
ENV POSTGRES_DB postgres

COPY demo-db.sql /docker-entrypoint-initdb.d/
