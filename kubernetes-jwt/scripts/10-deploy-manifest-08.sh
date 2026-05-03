#!/bin/bash

set -euo pipefail

# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Using kubectl/oc
COP_CLI=kubectl

# Namespace
NAMESPACE=conjur-jwt

# Fetch connection values from the existing ConfigMap
CONJUR_APPLIANCE_URL=$(kubectl get configmap conjur-connect -n "$NAMESPACE" -o jsonpath='{.data.CONJUR_APPLIANCE_URL}')
if command -p base64 -i "test" -w 0 > /dev/null 2>&1
then
    ONE_LINER_B64_CONJUR_CERTIFICATE=$(kubectl get configmap conjur-connect -n "$NAMESPACE" -o jsonpath='{.data.CONJUR_SSL_CERTIFICATE}' | base64 -w 0)
else
    ONE_LINER_B64_CONJUR_CERTIFICATE=$(kubectl get configmap conjur-connect -n "$NAMESPACE" -o jsonpath='{.data.CONJUR_SSL_CERTIFICATE}' | base64 -b 0)
fi
CONJUR_ACCOUNT=$(kubectl get configmap conjur-connect -n "$NAMESPACE" -o jsonpath='{.data.CONJUR_ACCOUNT}')
CONJUR_AUTHENTICATOR_ID=$(kubectl get configmap conjur-connect -n "$NAMESPACE" -o jsonpath='{.data.CONJUR_AUTHENTICATOR_ID}')

# Create a temporary Kustomize overlay
KUSTOMIZE_DIR=$(mktemp -d)
trap 'rm -rf "$KUSTOMIZE_DIR"' EXIT

cp "$SCRIPT_DIR/../manifests/08-jwt-eso.yml" "$KUSTOMIZE_DIR/"

cat > "$KUSTOMIZE_DIR/kustomization.yml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - 08-jwt-eso.yml
patches:
  - patch: |-
      - op: replace
        path: /spec/provider/conjur/url
        value: "${CONJUR_APPLIANCE_URL}"
      - op: replace
        path: /spec/provider/conjur/caBundle
        value: "${ONE_LINER_B64_CONJUR_CERTIFICATE}"
      - op: replace
        path: /spec/provider/conjur/auth/jwt/account
        value: "${CONJUR_ACCOUNT}"
      - op: replace
        path: /spec/provider/conjur/auth/jwt/serviceID
        value: "${CONJUR_AUTHENTICATOR_ID}"
    target:
      kind: SecretStore
      name: conjur
EOF

$COP_CLI apply -k "$KUSTOMIZE_DIR"
