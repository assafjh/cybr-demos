#!/bin/sh
# ---------------------------------------------------------------
# retrieve.sh — retrieves a secret from Conjur.
#
# AUTH_MODE controls how the Conjur access token is obtained:
#
#   pre-authenticated (default)
#     Reads an access-token from /run/conjur/access-token, written
#     by the Conjur authenticator-client sidecar/init container.
#     The sidecar handles authentication (can use authn-k8s with
#     certificate or authn-jwt — transparent to this script).
#     → 1 REST call: GET secret
#
#   self-authenticated
#     Reads the pod's K8s service-account JWT and authenticates
#     directly to Conjur via authn-jwt. No sidecar required.
#     → 2 REST calls: POST authenticate + GET secret
#
# Required environment variables:
#   CONJUR_APPLIANCE_URL  e.g. https://<tenant>.secretsmgr.cyberark.cloud/api
#   CONJUR_ACCOUNT        e.g. conjur
#   CONJUR_VARIABLE_PATH  e.g. data/kubernetes/applications/safe/secret1
#
# Required only for AUTH_MODE=self-authenticated:
#   CONJUR_AUTHN_URL      e.g. https://<tenant>.secretsmgr.cyberark.cloud/api/authn-jwt/k8s-cluster1
# ---------------------------------------------------------------

set -eu

# 1. Obtain a short-lived Conjur access token
if [ "${AUTH_MODE:-pre-authenticated}" = "self-authenticated" ]; then
  # Self-authenticated flow — the app exchanges its own JWT for a token
  JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  token=$(curl -k -s --request POST \
    "$CONJUR_AUTHN_URL/$CONJUR_ACCOUNT/authenticate" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --header "Accept-Encoding: base64" \
    --data-urlencode "jwt=$JWT")
else
  # Pre-authenticated flow — sidecar already wrote the token
  token=$(cat /run/conjur/access-token | base64 -w 0)
fi

# 2. Retrieve the secret from Conjur
secret=$(curl -k -s -X GET \
  -H "Authorization: Token token=\"$token\"" \
  "$CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$CONJUR_VARIABLE_PATH")

# 3. Print the retrieved value
echo "$CONJUR_VARIABLE_PATH value: $secret"
