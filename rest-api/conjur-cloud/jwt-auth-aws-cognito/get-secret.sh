#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
REGION="eu-west-2"
COGNITO_DOMAIN=""  
CLIENT_ID=""
CLIENT_SECRET=""
SCOPE="default-m2m-resource-server-XXXXX/read"

CONJUR_BASE_URL="https://TENANT.secretsmgr.cyberark.cloud/api"
CONJUR_ACCOUNT="conjur"
CONJUR_AUTHN_ID="aws-cognito"
CONJUR_LOGIN="host/data/aws-cognito/WORKLOAD_ID"
CONJUR_VARIABLE_PATH="data/vault/Conjur-ArgoCD/secret1/password"
# ====================

TOKEN_ENDPOINT="https://${COGNITO_DOMAIN}.auth.${REGION}.amazoncognito.com/oauth2/token"
AUTHN_ENDPOINT="${CONJUR_BASE_URL}/authn-jwt/${CONJUR_AUTHN_ID}/${CONJUR_ACCOUNT}/authenticate"
SECRET_ENDPOINT="${CONJUR_BASE_URL}/secrets/${CONJUR_ACCOUNT}/variable/${CONJUR_VARIABLE_PATH}"

die() { echo "[!] $*" >&2; exit 1; }

echo "[*] Requesting JWT from Cognito..."

JWT_RESPONSE="$(curl -sS -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_id=${CLIENT_ID}" \
  --data-urlencode "client_secret=${CLIENT_SECRET}" \
  --data-urlencode "scope=${SCOPE}"
)"

JWT="$(echo "$JWT_RESPONSE" | jq -r '.access_token')"

if [[ -z "${JWT}" || "${JWT}" == "null" ]]; then
  echo "$JWT_RESPONSE" >&2
  die "Failed to retrieve JWT from Cognito"
fi
echo "[+] JWT received from Cognito"

echo "[*] Authenticating to Conjur with JWT..."

# Put JWT in a file to avoid shell/history/process-list leakage and encoding issues
JWT_FILE="$(mktemp)"
trap 'rm -f "$JWT_FILE"' EXIT
printf '%s' "$JWT" > "$JWT_FILE"

# Send login in body (safer than query params with slashes)
CONJUR_TOKEN="$(curl -sS -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept-Encoding: base64" \
  --data-urlencode "jwt@${JWT_FILE}" \
  --data-urlencode "login=${CONJUR_LOGIN}" \
  "$AUTHN_ENDPOINT"
)"

if [[ -z "${CONJUR_TOKEN}" ]]; then
  die "Failed to authenticate to Conjur (empty token returned)"
fi
echo "[+] Conjur access token received"

echo "[*] Retrieving secret from Conjur..."

SECRET="$(curl -sS \
  -H "Authorization: Token token=\"${CONJUR_TOKEN}\"" \
  "$SECRET_ENDPOINT"
)"

echo
echo "[+] ${CONJUR_VARIABLE_PATH} value:"
echo "$SECRET"
