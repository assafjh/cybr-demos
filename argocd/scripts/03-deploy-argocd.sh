#!/bin/bash

# Using kubectl/oc
COP_CLI=kubectl

# Step 1: Create the namespace
$COP_CLI create namespace argocd

# Step 2: Apply the ArgoCD installation manifest
$COP_CLI apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3: Wait for ArgoCD to be ready
$COP_CLI wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Print ArgoCD initial admin password
echo "ArgoCD initial admin password:"
$COP_CLI -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo
