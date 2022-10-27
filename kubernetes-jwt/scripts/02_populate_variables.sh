#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=kubernetes/applications/safe/secret
# Using kubectl/oc
COP_CLI=kubectl
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Populate safe secrets with values
for i in {1..8}
do
   if command -p md5sum  >/dev/null 2>&1
    then
        conjur variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
    else
        conjur variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
    fi
done

# Populate authenticator values
conjur variable set -i conjur/authn-jwt/k8s-cluster1/identity-path -v "/kubernetes/applications"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/issuer -v "$(echo $($COP_CLI get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/token-app-property -v "sub"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$($COP_CLI get --raw /openid/v1/jwks)'}')"
