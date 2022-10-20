#!/bin/bash
# Populate safe secrets with values
safe_path=kubernetes/applications/safe/secret
conjur whoami
for i in {1..8}
do
   if command -p md5sum  >/dev/null 2>&1
    then
        conjur variable set -i "$safe_path$i" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
    else
        conjur variable set -i "$safe_path$i" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
    fi
done

# Populate authenticator values
conjur variable set -i conjur/authn-jwt/k8s-cluster1/identity-path -v "/kubernetes/applications"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/issuer -v "$(echo $(kubectl get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/token-app-property -v "sub"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$(kubectl get --raw /openid/v1/jwks)'}')"
