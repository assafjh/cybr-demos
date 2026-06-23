#!/usr/bin/env bash
set -euo pipefail

# Loads the two policy files into their respective branches.
# Prereq: conjur CLI installed + logged in (see 01-bootstrap.sh).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_DIR="${SCRIPT_DIR}/../policies"

# 01-base.yml defines the 'ansible' branch + admins → loads into data
echo "[1/2] Loading 01-base.yml into branch: data"
conjur policy update -b data -f "${POLICY_DIR}/01-base.yml"

# 02-define-branch.yml defines apps group, per-domain branches, host → loads into data/ansible
echo "[2/2] Loading 02-define-branch.yml into branch: data/ansible"
conjur policy update -b data/ansible -f "${POLICY_DIR}/02-define-branch.yml"

echo
echo "Done."
echo "IMPORTANT: the API key for host data/ansible/apps/conjur-demo is printed above on first load — copy it now, it is shown only once."
echo "Next: run 03-set-secrets.sh to inject credential values."