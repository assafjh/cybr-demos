#!/bin/bash

# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR/../server-patch || exit 1

# ArgoCD vault plugin and Conjur authenticator configuration
kubectl apply -k . 

# kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl delete svc argocd-server -n argocd
kubectl apply -f argocd-service-patch.yml -n argocd