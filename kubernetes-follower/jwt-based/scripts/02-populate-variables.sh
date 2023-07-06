#!/bin/bash
#============ Variables ===============
# Using kubectl/oc
COP_CLI=kubectl
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Populate authenticator values
conjur variable set -i conjur/authn-jwt/k8s-follower1/identity-path -v "/data/kubernetes/followers"
conjur variable set -i conjur/authn-jwt/k8s-follower1/issuer -v "$(echo $($COP_CLI get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
conjur variable set -i conjur/authn-jwt/k8s-follower1/token-app-property -v "sub"

# AWS EKS
# Well Known configuration link:
# https://oidc.eks.$REGION.amazonaws.com/id/$ID/.well-known/openid-configuration
# conjur variable set -i conjur/authn-jwt/k8s-follower1/public-keys -v "$(echo '{"type": "jwks","value":'$(curl -s https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys)}'')"
# conjur variable set -i conjur/authn-jwt/k8s-follower1/jwks-uri -v "https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys"

# Other Kubernetes platforms
conjur variable set -i conjur/authn-jwt/k8s-follower1/public-keys -v "$(echo '{"type": "jwks","value":'$($COP_CLI get --raw /openid/v1/jwks)'}')"

