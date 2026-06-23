#!/usr/bin/env bash
set -euo pipefail

# 1. Ansible collection
ansible-galaxy collection install cyberark.conjur

# 2. Conjur CLI sanity (after `conjur login` against the tenant)
echo "Identity check:"
conjur whoami

echo "If whoami works, you're ready to load policy."