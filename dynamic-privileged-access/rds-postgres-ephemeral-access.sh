#!/bin/bash

# DPA Tenant url for postgres reverse tunnnel
DPA_TENANT=demo.postgres.cyberark.cloud

#Generated Password - its valid for 120 mins
export PGPASSWORD="<your-dpa-ephemeral-password>"

# Username
USERNAME=<your-identity-username>

# Target DB
POSTGRES_DB=postgres

# Set connection timeput
export PGCONNECT_TIMEOUT=60

# Target RDS Postgres host we want to connect to
POSTGRES_HOST=<your-postgres-host.rds.amazonaws.com>
psql -U $USERNAME#$POSTGRES_DB@$POSTGRES_HOST -h $DPA_TENANT <<EOF
SELECT current_user;
SELECT current_database();
\du;
\conninfo
EOF

