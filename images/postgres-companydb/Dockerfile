FROM postgres:17-alpine

# OCI Labels
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Hardened PostgreSQL instance with enforced mTLS/SSL for secure demo environments"
LABEL org.opencontainers.image.licenses="MIT"

# Environment variables
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD="123456" 
ENV POSTGRES_DB=postgres

# Initial SQL Seed
COPY demo-db.sql /docker-entrypoint-initdb.d/

# Create a secure, non-volume directory for certificates
RUN mkdir -p /etc/ssl/postgresql && chown -R postgres:postgres /etc/ssl/postgresql

# Copy certificates from host
COPY ./certs/postgresdb.key ./certs/postgresdb.pem ./certs/rootCA.pem /etc/ssl/postgresql/

# Enforce strict permissions (MANDATORY for PostgreSQL SSL)
RUN chown postgres:postgres /etc/ssl/postgresql/* \
    && chmod 600 /etc/ssl/postgresql/postgresdb.key \
    && chmod 644 /etc/ssl/postgresql/postgresdb.pem \
    && chmod 644 /etc/ssl/postgresql/rootCA.pem

# We don't need to redefine ENTRYPOINT as it's inherited.
# CMD is appended to the entrypoint script automatically.
CMD ["-c", "ssl=on", \
     "-c", "ssl_cert_file=/etc/ssl/postgresql/postgresdb.pem", \
     "-c", "ssl_key_file=/etc/ssl/postgresql/postgresdb.key", \
     "-c", "ssl_ca_file=/etc/ssl/postgresql/rootCA.pem"]