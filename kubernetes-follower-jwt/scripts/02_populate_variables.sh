#!/bin/bash
#============ Variables ===============
# Using kubectl/oc
COP_CLI=kubectl
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Populate authenticator values
conjur variable set -i conjur/authn-jwt/k8s-cluster1/identity-path -v "/kubernetes/applications"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/issuer -v "$(echo $($COP_CLI get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/token-app-property -v "sub"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$($COP_CLI get --raw /openid/v1/jwks)'}')"
