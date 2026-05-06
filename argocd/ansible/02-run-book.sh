#!/bin/bash
set -euo pipefail

export CLIENT_ID=""
export CLIENT_SECRET=""

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" ]]; then
    echo "Error: CLIENT_ID and CLIENT_SECRET must be set before running this script."
    exit 1
fi

ansible-playbook safe-onboarding.yml

unset CLIENT_ID
unset CLIENT_SECRET
