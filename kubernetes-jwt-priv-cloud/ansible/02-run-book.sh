#!/bin/bash

# Set environment variables
export CLIENT_ID=""
export CLIENT_SECRET=""

# Run the Ansible playbook
ansible-playbook safe-onboarding.yml

# Unset environment variables
unset CLIENT_ID
unset CLIENT_SECRET
