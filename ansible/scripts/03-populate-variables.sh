#!/bin/bash
# This script populates Conjur safe secrets with securely generated values

set -euo pipefail

#============ Variables ===============
# Note: The base path is aligned with app.yml
SAFE_BASE_PATH="data/ansible/apps/safe"
CONJUR_CLI="conjur"

# Array of specific secrets to populate
SECRETS=("db_password" "api_key" "ssh_key")

#============ Script ===============

echo "Verifying Conjur CLI authentication..."
if ! "$CONJUR_CLI" whoami > /dev/null 2>&1; then
    echo "Error: You are not logged into Conjur CLI. Please log in first."
    exit 1
fi

echo "Successfully authenticated. Populating secrets..."

for SECRET_NAME in "${SECRETS[@]}"; do
    if command -v openssl > /dev/null 2>&1; then
        SECRET_VAL=$(openssl rand -hex 12)
    else
        SECRET_VAL=$(head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n')
    fi

    FULL_PATH="${SAFE_BASE_PATH}/${SECRET_NAME}"
    echo "Setting variable: ${FULL_PATH}"
    if ! "$CONJUR_CLI" variable set -i "$FULL_PATH" -v "$SECRET_VAL"; then
        echo "Error: Failed to set ${FULL_PATH}"
        exit 1
    fi
done

echo "Secrets populated successfully."
