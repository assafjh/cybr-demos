#!/bin/bash
# This script installs the Conjur Ansible galaxy plugin based on the Ansible version

set -euo pipefail

#========== Script ===============
FUNCTIONS_FILE="./functions"

if [[ -f "$FUNCTIONS_FILE" ]]; then
    source "$FUNCTIONS_FILE"
else
    echo "Error: Functions file not found at $FUNCTIONS_FILE"
    exit 1
fi

# Plugin needed will be decided according to Ansible version
decide_values_for_playbook

echo "Detected Ansible plugin requirement: $ANSIBLE_PLUGIN"

if [[ "$ANSIBLE_PLUGIN" == "new" ]]; then
    ansible-galaxy collection install cyberark.conjur
elif [[ "$ANSIBLE_PLUGIN" == "old" ]]; then
    ansible-galaxy install cyberark.conjur-host-identity
else
    echo "Error: Plugin not supported. Minimum supported version is Ansible 2.8"
    exit 1
fi