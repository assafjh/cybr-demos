#!/bin/sh

echo "=========================================================="
echo " Starting Secretless Broker Demo App                      "
echo " Connection: postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "=========================================================="
echo ""

psql "postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" << EOSQL
\conninfo
select current_user;
select * from ${TABLE_NAME};
EOSQL

echo ""
echo "[INFO] Container is now sleeping. To test interactively, run:"
echo "       /scripts/query-database.sh"
exec sleep infinity