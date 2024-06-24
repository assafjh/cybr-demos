#!/bin/bash

# Using kubectl/oc
COP_CLI=kubectl

# Step 1: Create the namespace
$COP_CLI create namespace argocd

# Step 2: Apply the ArgoCD installation manifest
$COP_CLI apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3: Wait for ArgoCD to be ready
$COP_CLI wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Step 4: Patch the ArgoCD server service to be of type LoadBalancer and set custom port
$COP_CLI patch svc argocd-server -n argocd --type=json -p='[{
  "op": "replace",
  "path": "/spec/type",
  "value": "LoadBalancer"
}, {
  "op": "replace",
  "path": "/spec/ports",
  "value": [
    {
      "port": 8082,
      "targetPort": 8080,
      "name": "http"
    }
  ]
}]'

# Step 5: Set the admin password - SomePass123@
$COP_CLI -n argocd patch secret argocd-secret -p='{"stringData": {
    "admin.password": "$2a$12$hSl5BgSxu2Iy96zlTdFgBuc5nL9v1eQe2Mim1Pz1Jl/UJMv1jv7Xm",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

# Print ArgoCD initial admin password
#echo "ArgoCD initial admin password:"
#$COP_CLI -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo

# Step 6: Print admin password
echo "admin password configured: SomePass123@"
echo "service is exposed under port 8082"