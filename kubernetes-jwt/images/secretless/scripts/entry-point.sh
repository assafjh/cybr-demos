#!/bin/sh
psql "postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" << EOSQL
\conninfo
select current_user;
select * from ${TABLE_NAME};
EOSQL
sleep 3600