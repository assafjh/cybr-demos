#!/bin/bash
# This script prepares and runs the Ansible playbook securely

set -euo pipefail

#========== Initialization ===============
if [[ -f ".env" ]]; then
    export $(grep -v '^#' .env | xargs)
fi

# Validate critical Conjur environment variables exist
: "${CONJUR_ACCOUNT:?Must be set}"
: "${CONJUR_APPLIANCE_URL:?Must be set}"
: "${CONJUR_AUTHN_LOGIN:?Must be set}"
: "${CONJUR_AUTHN_API_KEY:?Must be set}"

export CONJUR_CERT_FILE=${CONJUR_CERT_FILE:-"$HOME/conjur-server.pem"}

FUNCTIONS_FILE="./functions"
if [[ -f "$FUNCTIONS_FILE" ]]; then
    source "$FUNCTIONS_FILE"
else
    echo "Error: Functions file not found at $FUNCTIONS_FILE"
    exit 1
fi

#========== Script ===============
# This function (from your ./functions) sets LOOKUP_CMD and ANSIBLE_PLUGIN
decide_values_for_playbook

cd ../playbook || { echo "Error: Could not navigate to ../playbook"; exit 1; }

echo "Running Ansible Playbook natively..."

# Best Practice: Inject only the required dynamic lookup command via Extra Vars
ansible-playbook playbook.yml \
  -e "lookup_cmd=$LOOKUP_CMD" \
  -vv