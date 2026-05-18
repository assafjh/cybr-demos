#!/bin/bash
set -euo pipefail
# Authenticates to Conjur Cloud using an EC2 IAM role, then retrieves a secret.
# Prerequisites: CONJUR_FQDN, PORT, and ARN_ROLE must be exported before running.
#   export CONJUR_FQDN=<your-tenant>.secretsmgr.cyberark.cloud
#   export PORT=443
#   export ARN_ROLE=<your-iam-role-name>

#============ Variables ===============
PYTHON=python3
VENV_DIR=".venv"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

#============ Checks ===============
if ! command -v "$PYTHON" &>/dev/null; then
    echo "Error: python3 not found. Please install Python 3.9 or later."
    exit 1
fi

PY_MINOR=$("$PYTHON" -c 'import sys; print(sys.version_info.minor)')
PY_MAJOR=$("$PYTHON" -c 'import sys; print(sys.version_info.major)')
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 9 ]; }; then
    echo "Error: Python 3.9 or later is required (found $("$PYTHON" --version))."
    exit 1
fi

for var in CONJUR_FQDN PORT ARN_ROLE; do
    if [ -z "${!var}" ]; then
        echo "Error: \$$var is not set. See usage at the top of this script."
        exit 1
    fi
done

#============ Setup ===============
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    "$PYTHON" -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo "Installing dependencies..."
pip install -r "$SCRIPT_DIR/requirements.txt" --quiet

# shellcheck disable=SC1091
source "$SCRIPT_DIR/.env"

#============ Run ===============
echo "Running demo..."
"$PYTHON" "$SCRIPT_DIR/ec2.py"
