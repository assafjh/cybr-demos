#!/bin/bash
# This script will enable an Authenticator in Conjur.
# For Conjur Cloud - This script Needs access to Conjur Cloud CLI.
#============ Variables =======================
# Name of the authn to enable, leave as is
#AUTHN_TO_ENABLE=authn-jwt/k8s-argocd1
AUTHN_TO_ENABLE=authn-jwt/k8s-argocd1
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=conjur

#============ Script ===============
"$CONJUR_CLI" authenticator enable --id  "${AUTHN_TO_ENABLE}"