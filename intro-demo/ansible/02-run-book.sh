#!/bin/bash

# Set environment variables
export CLIENT_ID="assaf-sa@assaflab"
export CLIENT_SECRET="SomePass123@"

# Run the Ansible playbook
ansible-playbook safe-onboarding.yml

# Unset environment variables
unset CLIENT_ID
unset CLIENT_SECRET
