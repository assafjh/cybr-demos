#!/bin/bash
# This script installs eso using helm.
# If helm is not installed, the script will install helm.

#============ Variables ===============
NAMESPACE=external-secrets

#============ Script ===============
if ! command -v helm >/dev/null 2>&1
then
  echo "Installing helm"
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

helm repo add external-secrets https://charts.external-secrets.io

# Install ESO
helm install external-secrets \
   external-secrets/external-secrets \
    -n $NAMESPACE \
    --create-namespace \
    --set installCRDs=true
