#!/bin/bash
# This script deploys the Ansible AWX Operator and a demo AWX instance

set -euo pipefail

#================ Variables ==============
# Using kubectl (or oc for OpenShift environments)
COP_CLI="kubectl"
MANIFESTS_DIR="../manifests"

#================ Script ==============
echo "Verifying prerequisites..."
if ! command -v "$COP_CLI" >/dev/null 2>&1; then
    echo "Error: $COP_CLI is not installed or not in PATH."
    exit 1
fi

cd "$MANIFESTS_DIR" || { echo "Error: Could not navigate to $MANIFESTS_DIR"; exit 1; }

echo "Deploying AWX Operator and Instance..."

# Architecture Note: 
# When deploying an Operator and its Custom Resource (CR) simultaneously via Kustomize,
# the first apply often fails because the CRD isn't fully registered by the API server yet.
# We attempt the apply, catch the expected race-condition failure, wait, and apply again safely.

if ! $COP_CLI apply -k .; then
    echo "Initial apply encountered expected CRD race conditions. Waiting for CRDs to register..."
    sleep 10
    echo "Re-applying to deploy the AWX instance..."
    $COP_CLI apply -k .
fi

echo "================================================="
echo "Deployment initiated successfully."
echo "To monitor the AWX pod deployment progress, run:"
echo "$COP_CLI get pods -n awx -w"
echo "================================================="