#!/usr/bin/env bash
set -euo pipefail
# UPDATE values. Run after load_policy.sh.

# Domain 1
conjur variable set -i data/ansible/domain1.corp/username -v 'svc-ansible@domain1.corp'
conjur variable set -i data/ansible/domain1.corp/password -v 'CHANGE_ME_1'

# Domain 2
conjur variable set -i data/ansible/domain2.corp/username -v 'svc-ansible@domain2.corp'
conjur variable set -i data/ansible/domain2.corp/password -v 'CHANGE_ME_2'

echo "Secrets set. Verify:"
echo "  conjur variable get -i data/ansible/domain1.corp/password"