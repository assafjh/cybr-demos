#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

#============ Variables ===============
NAMESPACE="external-secrets"
RELEASE_NAME="external-secrets"
ESO_VERSION="0.9.18"

#============ Helper Functions ===============
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#============ 1. Helm Installation (Idempotent) ===============
if command_exists helm; then
    echo "✔ Helm is already installed."
else
    echo "Helm is not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
        brew install helm
    else
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
fi

#============ 2. Kubernetes Connection Check ===============
if ! command_exists kubectl; then
    echo "ERROR: 'kubectl' is not installed."
    exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

#============ 3. ESO Installation Check (Idempotent) ===============
INSTALLED_VERSION=$(helm list -n "$NAMESPACE" -f "^${RELEASE_NAME}$" -o json | grep -o '"chart":"external-secrets-[^"]*"' | cut -d'-' -f3 | tr -d '"' || true)

if [[ "$INSTALLED_VERSION" == "$ESO_VERSION" ]]; then
    echo "✔ External Secrets Operator (v${ESO_VERSION}) is already installed and up to date in namespace '$NAMESPACE'. Skipping installation."
    exit 0
fi

#============ 4. Deploy / Upgrade ESO ===============
echo "Updating Helm repositories..."
helm repo add external-secrets https://charts.external-secrets.io --force-update

echo "Installing/Upgrading External Secrets Operator to v${ESO_VERSION}..."
helm upgrade --install "$RELEASE_NAME" \
    external-secrets/external-secrets \
    -n "$NAMESPACE" \
    --create-namespace \
    --version "$ESO_VERSION" \
    --set installCRDs=true

echo "✔ Successfully deployed External Secrets Operator!"