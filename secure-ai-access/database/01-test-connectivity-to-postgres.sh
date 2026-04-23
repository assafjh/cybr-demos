#!/bin/bash
# This script will check connection to the postgres server that was deployed with the terraform plan
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Postgres server host
REMOTE_DB_HOST=ajh-postgres
# Postgres server port
REMOTE_DB_PORT=5432
#================ Script ==============
$SUDO $CONTAINER_MGR run -i --rm -e PGPASSWORD=123456 docker.io/assafhazan/postgres-companydb:17-alpine \
  psql -U admin "postgres://${REMOTE_DB_HOST}:${REMOTE_DB_PORT}/companydb" <<EOF

\x auto

SELECT 'Counting customers...' AS step;
SELECT COUNT(*) FROM customers;

SELECT 'Counting orders...' AS step;
SELECT COUNT(*) FROM orders;

SELECT 'Counting support tickets...' AS step;
SELECT COUNT(*) FROM support_tickets;

SELECT 'Revenue per tier...' AS step;
SELECT c.tier, COUNT(o.id) AS orders, SUM(o.amount_usd) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.tier;

EOF

echo "Done."
