#!/bin/bash
# This script will check ZSP read-only connection to the postgres server via CyberArk SIA using MFA Cache Token

#============ SIA Variables (UPDATE THESE!) ===============
# Your CyberArk Tenant Subdomain (e.g., "mycompany")
TENANT_SUBDOMAIN="tiger-prod"

# Your CyberArk Identity Username (e.g., "ajh@mycompany.com")
CYBERARK_USER="ahazan@tiger.com"

# Postgres target FQDN as defined in SIA
TARGET_FQDN="ec2-13-135-62-241.eu-west-2.compute.amazonaws.com"

# MFA cached password - this is the value that SIA will return when the MFA challenge is completed successfully. You can get this value from the SIA logs, or by running the SIA connector locally and checking the output after completing the MFA challenge.
MFA_TOKEN=cybrsso90oEkm1CogAkp+Rqa7JDPK3juKDp5Ec7hW7Ed6i0kyw=

#============ System Variables ===============
SUDO=
CONTAINER_MGR=docker
REMOTE_DB_PORT=5432

# SIA Gateway for Postgres
SIA_DB_HOST="${TENANT_SUBDOMAIN}.postgres.cyberark.cloud"

# Constructing the SIA User string for ZSP
# Format: <username>@<login_suffix>#<tenant-subdomain>@<target-fqdn>
SIA_USER="${CYBERARK_USER}#${TENANT_SUBDOMAIN}@${TARGET_FQDN}"

#================ Script ==============
$SUDO $CONTAINER_MGR run -i --rm -e PGPASSWORD="${MFA_TOKEN}" docker.io/assafhazan/postgres-companydb:17-alpine \
  psql "host=${SIA_DB_HOST} port=${REMOTE_DB_PORT} user=${SIA_USER} dbname=companydb" <<EOF

\x auto

SELECT '--- IDENTITY CHECK ---' AS step;

SELECT current_user AS "Current Ephemeral User";

SELECT rolname AS "Assigned Roles"
FROM pg_roles 
WHERE pg_has_role(current_user, oid, 'member') 
AND rolname != current_user;

SELECT '--- PERMISSION CHECK ---' AS step;
SELECT 'Counting customers...' AS task;
SELECT COUNT(*) FROM customers;

SELECT 'Attempting unauthorized write...' AS task;
CREATE TABLE check_identity_table (id INT);

EOF

echo "Done."