#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=data/kubernetes/applications/safe/
# Using kubectl/oc
COP_CLI=kubectl
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=conjur
# Postgres username and password details
APPLICATION_DB_USER=reception
APPLICATION_DB_PASSWORD=vet_123456
APPLICATION_DB_HOST=$DB_HOSTNAME
APPLICATION_DB_PORT=5432
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate safe secrets with values
for i in {1..8}
do
   if command -p md5sum  /dev/null >/dev/null 2>&1
    then
        "$CONJUR_CLI" variable set -i "${SAFE_PATH}secret$i" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
    else
        "$CONJUR_CLI" variable set -i "${SAFE_PATH}secret$i" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
    fi
done
"$CONJUR_CLI" variable set -i "${SAFE_PATH}postgres-username" -v "$APPLICATION_DB_USER"
"$CONJUR_CLI" variable set -i "${SAFE_PATH}postgres-password" -v "$APPLICATION_DB_PASSWORD"
"$CONJUR_CLI" variable set -i "${SAFE_PATH}postgres-hostname" -v "$APPLICATION_DB_HOST"
"$CONJUR_CLI" variable set -i "${SAFE_PATH}postgres-port" -v "$APPLICATION_DB_PORT"

# Populate authenticator values
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/identity-path -v "/data/kubernetes/applications"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/issuer -v "$(echo $($COP_CLI get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/token-app-property -v "sub"

# AWS EKS
# Well Known configuration link:
# https://oidc.eks.$REGION.amazonaws.com/id/$ID/.well-known/openid-configuration
# "$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$(curl -s https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys)}'')"
# "$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/jwks-uri -v "https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys"

# Other Kubernetes platforms
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$($COP_CLI get --raw /openid/v1/jwks)'}')"

