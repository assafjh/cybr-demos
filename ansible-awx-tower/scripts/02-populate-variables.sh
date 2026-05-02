#!/bin/bash
# This script populates Conjur safe secrets for AWX with securely generated values

set -euo pipefail

#============ Variables ===============
# Note: The base path is aligned with the AWX app.yml policy
SAFE_BASE_PATH="data/ansible/apps/safe"
CONJUR_CLI="conjur"

# Array of specific secrets to populate (Aligned perfectly with the AWX Credential Types)
SECRETS=("ansible_password" "db_password" "api_key" "ssh_key")

#============ Script ===============

echo "Verifying Conjur CLI authentication..."
if ! "$CONJUR_CLI" whoami > /dev/null 2>&1; then
    echo "Error: You are not logged into Conjur CLI. Please log in first."
    exit 1
fi

echo "Successfully authenticated. Populating AWX secrets..."

for SECRET_NAME in "${SECRETS[@]}"; do
    # Using openssl for a more secure standard of random secret generation
    if command -v openssl > /dev/null 2>&1; then
        # Generating a 16-byte hex string (32 characters) for strong AWX secrets
        SECRET_VAL=$(openssl rand -hex 16)
    else
        # Fallback if openssl is not installed
        SECRET_VAL=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
    fi
    
    FULL_PATH="${SAFE_BASE_PATH}/${SECRET_NAME}"
    echo "Setting variable: ${FULL_PATH}"
    "$CONJUR_CLI" variable set -i "$FULL_PATH" -v "$SECRET_VAL"
done

echo "AWX secrets populated successfully."