FROM postgres:11.2-alpine
LABEL maintainer=AssafHazan

ENV POSTGRES_USER admin
ENV POSTGRES_PASSWORD 123456
ENV POSTGRES_DB postgres

COPY demo-db.sql /docker-entrypoint-initdb.d/

COPY ./certs/postgresdb.key /var/lib/postgresql
COPY ./certs/postgresdb.pem /var/lib/postgresql

COPY ./certs/rootCA.pem /var/lib/postgresql

RUN chown 0:70 /var/lib/postgresql/postgresdb.key && chmod 640 /var/lib/postgresql/postgresdb.key \
    && chown 0:70 /var/lib/postgresql/postgresdb.pem && chmod 640 /var/lib/postgresql/postgresdb.pem \
    && chown 0:70 /var/lib/postgresql/rootCA.pem && chmod 640 /var/lib/postgresql/rootCA.pem

ENTRYPOINT ["docker-entrypoint.sh"] 

CMD [ "-c", "ssl=on" , "-c", "ssl_cert_file=/var/lib/postgresql/postgresdb.pem", "-c",\
    "ssl_key_file=/var/lib/postgresql/postgresdb.key", "-c",\
    "ssl_ca_file=/var/lib/postgresql/rootCA.pem" ]
