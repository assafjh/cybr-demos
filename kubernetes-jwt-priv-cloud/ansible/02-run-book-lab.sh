#!/bin/bash

# Set environment variables
export CLIENT_ID="ajh-service-account@cyberark.cloud.8128"
export CLIENT_SECRET="SomePass135@"
export IDENTITY_TENANT="aau4939"
export PRIV_TENANT="emeadevops"
export SAFE_OWNER="assaf_hazan@cyberark.cloud.8128"

cleanup() {
    unset CLIENT_ID CLIENT_SECRET IDENTITY_TENANT PRIV_TENANT SAFE_OWNER
}
trap cleanup EXIT

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$IDENTITY_TENANT" || -z "$PRIV_TENANT" ]]; then
    echo "ERROR: One or more required environment variables are not set!"
    exit 1
fi

ansible-playbook safe-onboarding.yml
