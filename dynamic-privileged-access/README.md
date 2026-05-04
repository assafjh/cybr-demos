# Dynamic Privileged Access (DPA) Demo

This directory contains a script demonstrating how to connect to a target RDS PostgreSQL database using CyberArk Dynamic Privileged Access (DPA) ephemeral access.

## Files

- `rds-postgres-ephemeral-access.sh`: A bash script that uses `psql` to connect to a target database through the DPA tenant gateway, using an ephemeral password valid for a short duration.

## Usage

1. Open `rds-postgres-ephemeral-access.sh` and ensure the placeholders (`<your-dpa-ephemeral-password>`, `<your-identity-username>`, `<your-postgres-host.rds.amazonaws.com>`) are filled in with your actual temporary credentials and target host.
2. Run the script:
   ```bash
   bash rds-postgres-ephemeral-access.sh
   ```

The script will connect to the database and print the current user, current database, and connection info.
