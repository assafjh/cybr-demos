#!/bin/bash
set -euo pipefail

#============ Variables ===============
COP_CLI=kubectl

#============ Script ===============
"$COP_CLI" create namespace argocd

"$COP_CLI" apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

"$COP_CLI" wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

echo "ArgoCD initial admin password:"
"$COP_CLI" -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode && echo
