#!/bin/bash

# Set environment variables
export CLIENT_ID="<your-client-account>"
export CLIENT_SECRET="<your-client-secret>"

# Run the Ansible playbook
ansible-playbook safe-onboarding.yml

# Unset environment variables
unset CLIENT_ID
unset CLIENT_SECRET
