#!/bin/bash

# DPA Tenant url for postgres reverse tunnnel
DPA_TENANT=demo.postgres.cyberark.cloud

#Generated Password - its valid for 120 mins
export PGPASSWORD="vOFR3OOd6IQA+HpF0Hlyp2CI6mulGcz1IFnNr27o1yI="

# Username
USERNAME=assaf.hazan@cyberarklab.com

# Target DB
POSTGRES_DB=postgres

# Set connection timeput
export PGCONNECT_TIMEOUT=60

# Target RDS Postgres host we want to connect to
POSTGRES_HOST=cw-postgres.clv2dmjtgp2g.us-east-2.rds.amazonaws.com
psql -U $USERNAME#$POSTGRES_DB@$POSTGRES_HOST -h $DPA_TENANT <<EOF
SELECT current_user;
SELECT current_database();
\du;
\conninfo
EOF

