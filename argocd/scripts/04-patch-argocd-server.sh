#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR/../server-patch"

# Apply ArgoCD vault plugin + Conjur authenticator configuration
kubectl apply -k .