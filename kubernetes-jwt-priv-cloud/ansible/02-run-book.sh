#!/bin/bash

# Set environment variables
export CLIENT_ID=""
export CLIENT_SECRET=""
export IDENTITY_TENANT=""
export PRIV_TENANT=""
export SAFE_OWNER=""

cleanup() {
    unset CLIENT_ID CLIENT_SECRET IDENTITY_TENANT PRIV_TENANT SAFE_OWNER
}
trap cleanup EXIT

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$IDENTITY_TENANT" || -z "$PRIV_TENANT" ]]; then
    echo "ERROR: One or more required environment variables are not set!"
    exit 1
fi

ansible-playbook safe-onboarding.yml