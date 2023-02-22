#!/bin/bash
#============ Variables ===============
# Using kubectl/oc
COP_CLI=kubectl
# Postgres username and password details
APPLICATION_DB_USER=reception
APPLICATION_DB_PASSWORD=vet_123456
APPLICATION_DB_HOST=$DB_HOSTNAME
APPLICATION_DB_PORT=5432
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Populate safe secrets with values
conjur variable set -i "kubernetes/applications/safe/postgres-username" -v "$APPLICATION_DB_USER"
conjur variable set -i "kubernetes/applications/safe/postgres-password" -v "$APPLICATION_DB_PASSWORD"
conjur variable set -i "kubernetes/applications/safe/postgres-hostname" -v "$APPLICATION_DB_HOST"
conjur variable set -i "kubernetes/applications/safe/postgres-port" -v "$APPLICATION_DB_PORT"

# Populate authenticator values
conjur variable set -i conjur/authn-jwt/k8s-cluster1/identity-path -v "/kubernetes/applications"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/issuer -v "$(echo $($COP_CLI get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
conjur variable set -i conjur/authn-jwt/k8s-cluster1/token-app-property -v "sub"

# AWS EKS
# Well Known configuration link:
# https://oidc.eks.$REGION.amazonaws.com/id/$ID/.well-known/openid-configuration
# conjur variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$(curl -s https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys)}'')"
# conjur variable set -i conjur/authn-jwt/k8s-cluster1/jwks-uri -v "https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys"

# Other Kubernetes platforms
conjur variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$($COP_CLI get --raw /openid/v1/jwks)'}')"

