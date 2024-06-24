#!/bin/bash
#============ Variables ===============
# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Using kubectl/oc
COP_CLI=kubectl
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=conjur

#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate authenticator values
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-argocd1/identity-path -v "/data/argocd"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-argocd1/issuer -v "$(echo $($COP_CLI get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-argocd1/token-app-property -v "sub"

# AWS EKS
# Well Known configuration link:ß
# https://oidc.eks.$REGION.amazonaws.com/id/$ID/.well-known/openid-configuration
# "$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-argocd1/public-keys -v "$(echo '{"type": "jwks","value":'$(curl -s https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys)}'')"
# "$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-argocd1/jwks-uri -v "https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys"

# Other Kubernetes platforms
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-argocd1/public-keys -v "$(echo '{"type": "jwks","value":'$($COP_CLI get --raw /openid/v1/jwks)'}')"

