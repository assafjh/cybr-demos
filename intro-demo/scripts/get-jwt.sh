#!/usr/bin/env bash

# ====== CONFIG ======
REGION="eu-west-2"
USER_POOL_ID="eu-west-2_fDn0jCiEv"
COGNITO_DOMAIN="eu-west-2fdn0jciev"  
CLIENT_ID="7j03g529sdski9nde886qac460"
CLIENT_SECRET="15i4e2p9qtpictt1n31f782c9c65m3jquq57jkijhd9cehu3i5gk"
SCOPE="default-m2m-resource-server-di4ppx/read"
# ====================

TOKEN_ENDPOINT="https://${COGNITO_DOMAIN}.auth.${REGION}.amazoncognito.com/oauth2/token"

echo "[*] Requesting access token from Cognito..."

RESPONSE=$(curl -s -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "scope=${SCOPE}"
)

ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')

if [[ "$ACCESS_TOKEN" == "null" || -z "$ACCESS_TOKEN" ]]; then
  echo "[!] Failed to retrieve access token"
  echo "$RESPONSE"
  exit 1
fi

echo "[+] Access token received"
echo
echo "===== JWT (Bearer Token) ====="
echo "$ACCESS_TOKEN"
echo
echo "Issuer (for Conjur):"
echo "https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}"
echo
echo "JWKS URI (for Conjur):"
echo "https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}/.well-known/jwks.json"
