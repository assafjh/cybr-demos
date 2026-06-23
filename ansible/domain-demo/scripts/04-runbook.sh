#!/bin/bash
set -euo pipefail
# macOS-only: Objective-C fork-safety workaround (no-op on Linux/WSL)
[[ "$(uname)" == "Darwin" ]] && export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load Conjur auth env
if [[ -f ".env" ]]; then
    set -a; source .env; set +a
fi
: "${CONJUR_ACCOUNT:?Must be set}"
: "${CONJUR_APPLIANCE_URL:?Must be set}"
: "${CONJUR_AUTHN_LOGIN:?Must be set}"
: "${CONJUR_AUTHN_API_KEY:?Must be set}"

cd ../playbook || { echo "Error: cannot cd to ../playbook"; exit 1; }

echo "Running domain-based retrieval playbook..."
ansible-playbook playbook.yml -vv