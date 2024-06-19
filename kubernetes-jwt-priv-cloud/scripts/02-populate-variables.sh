#!/bin/bash
#============ Variables ===============
# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Path to our safe at Conjur, leave as is
SAFE_PATH=data/kubernetes/applications/safe/
# Using kubectl/oc
COP_CLI=kubectl
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=/Applications/ConjurCloudCLI.app/Contents/Resources/conjur/conjur

#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate messenger app value
"$CONJUR_CLI" variable set -i data/kubernetes/applications/safe/messenger -v "$(cat "${SCRIPT_DIR}"/../go/bin/messenger.b64)"

# Populate authenticator values
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/identity-path -v "/data/kubernetes/applications"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/issuer -v "$(echo $($COP_CLI get --raw /.well-known/openid-configuration | awk -F "," '{print $1}' | tr -d '",' | sed 's#{issuer:##g'))"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/token-app-property -v "sub"

# AWS EKS
# Well Known configuration link:ß
# https://oidc.eks.$REGION.amazonaws.com/id/$ID/.well-known/openid-configuration
# "$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$(curl -s https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys)}'')"
# "$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/jwks-uri -v "https://oidc.eks.$REGION.amazonaws.com/id/$ID/keys"

# Other Kubernetes platforms
"$CONJUR_CLI" variable set -i conjur/authn-jwt/k8s-cluster1/public-keys -v "$(echo '{"type": "jwks","value":'$($COP_CLI get --raw /openid/v1/jwks)'}')"

