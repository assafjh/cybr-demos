#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# run-deploy.sh
# Thin wrapper around the VENDOR'S UNMODIFIED deploy.sh.
# Reads names + subscription from scanner.conf and feeds deploy.sh's prompts so
# you don't retype. deploy.sh itself is NOT touched - drop in vendor updates freely.
#
# SAFETY:
#  - The CyberArk password is read HIDDEN here and passed to deploy.sh over a
#    stdin pipe only. It is never written to disk, never appears in process args
#    (so not visible in `ps`), and is unset afterwards.
#  - Requires a CLEAN state (no pre-existing app registration) so the prompt
#    order stays in sync. Run the CLEANUP first. The wrapper guards against this.
#
# Usage:  bash run-deploy.sh
# =============================================================================

CONF_FILE="${SCANNER_CONF:-scanner.conf}"
DEPLOY="${DEPLOY_SCRIPT:-./deploy.sh}"   # the vendor's ORIGINAL deploy.sh

[[ -f "$CONF_FILE" ]] || { echo "Missing $CONF_FILE - copy scanner.conf.example and fill it in."; exit 1; }
[[ -f "$DEPLOY" ]]    || { echo "Missing $DEPLOY - put the vendor deploy.sh here (or set DEPLOY_SCRIPT)."; exit 1; }
command -v az >/dev/null 2>&1 || { echo "Azure CLI (az) not found."; exit 1; }

# ---- parse scanner.conf (CRLF-safe, no 'source' so no code execution) ----
SUBSCRIPTION_ID=""; LOCATION=""; RESOURCE_GROUP=""; FUNCTION_APP=""
STORAGE_ACCOUNT=""; APP_SERVICE_PLAN=""; KEY_VAULT=""; APP_INSIGHTS=""; APP_REGISTRATION=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"; line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  key="${line%%=*}"; val="${line#*=}"; key="${key//[[:space:]]/}"
  val="${val%$'\r'}"; val="${val#"${val%%[![:space:]]*}"}"
  val="${val%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"
  case "$key" in
    SUBSCRIPTION_ID)  SUBSCRIPTION_ID="$val";;
    LOCATION)         LOCATION="$val";;
    RESOURCE_GROUP)   RESOURCE_GROUP="$val";;
    FUNCTION_APP)     FUNCTION_APP="$val";;
    STORAGE_ACCOUNT)  STORAGE_ACCOUNT="$val";;
    APP_SERVICE_PLAN) APP_SERVICE_PLAN="$val";;
    KEY_VAULT)        KEY_VAULT="$val";;
    APP_INSIGHTS)     APP_INSIGHTS="$val";;
    APP_REGISTRATION) APP_REGISTRATION="$val";;
  esac
done < "$CONF_FILE"

# ---- every prompted name must be present, or the stdin feed desyncs ----
miss=""
for pair in "RESOURCE_GROUP:$RESOURCE_GROUP" "FUNCTION_APP:$FUNCTION_APP" \
            "STORAGE_ACCOUNT:$STORAGE_ACCOUNT" "APP_SERVICE_PLAN:$APP_SERVICE_PLAN" \
            "KEY_VAULT:$KEY_VAULT" "APP_INSIGHTS:$APP_INSIGHTS" "APP_REGISTRATION:$APP_REGISTRATION"; do
  [[ -z "${pair#*:}" ]] && miss="$miss ${pair%%:*}"
done
[[ -n "$miss" ]] && { echo "scanner.conf is missing required value(s):$miss"; exit 1; }

# ---- select the target subscription by ID (or confirm the active one) ----
if [[ -n "$SUBSCRIPTION_ID" ]]; then
  az account set --subscription "$SUBSCRIPTION_ID"
else
  echo "WARNING: SUBSCRIPTION_ID is empty in $CONF_FILE - no subscription is pinned."
  echo "Active subscription: $(az account show --query '[name,id]' -o tsv | tr '\t' ' ')"
  read -rp "Deploy into THIS subscription? [y/N]: " SUBOK
  [[ "$SUBOK" =~ ^[Yy]$ ]] || { echo "Aborted. Set SUBSCRIPTION_ID in $CONF_FILE, or: az account set --subscription <ID>"; exit 1; }
fi
echo "Active subscription: $(az account show --query '[name,id]' -o tsv | tr '\t' ' ')"
echo "Names: RG=$RESOURCE_GROUP FUNC=$FUNCTION_APP SA=$STORAGE_ACCOUNT PLAN=$APP_SERVICE_PLAN KV=$KEY_VAULT AI=$APP_INSIGHTS APP=$APP_REGISTRATION"

# ---- guard: the automated feed assumes NO existing app registration ----
EXIST="$(az ad app list --display-name "$APP_REGISTRATION" --query "[0].appId" -o tsv 2>/dev/null || true)"
if [[ -n "$EXIST" ]]; then
  echo
  echo "STOP: app registration '$APP_REGISTRATION' already exists ($EXIST)."
  echo "The vendor deploy.sh would insert a reuse prompt that desyncs the automated feed."
  echo "Run CLEANUP to remove it first, or run the vendor deploy.sh interactively."
  exit 1
fi

# ---- credentials: read HERE (hidden password), never written to disk ----
echo
echo "CyberArk service user (press Enter at the tenant prompt to deploy WITHOUT triggering the scan):"
read -rp "  Tenant subdomain: " CA_TENANT
CA_USER=""; CA_PASS=""
if [[ -n "$CA_TENANT" ]]; then
  read -rp "  Username: " CA_USER
  read -srp "  Password: " CA_PASS; echo
fi

echo
echo "Handing off to $DEPLOY with pre-filled answers (it is unmodified)..."

# Pre-create the RG in the desired LOCATION. The vendor deploy.sh hardcodes its
# own region in its 'az group create'; running against an already-existing RG
# makes that a no-op (RG location is immutable), so YOUR LOCATION is honored and
# the bicep resources inherit it. Skipped if the RG already exists.
if [[ -n "$LOCATION" ]] && ! az group show -n "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Creating resource group '$RESOURCE_GROUP' in '$LOCATION' (so the region is honored)..."
  az group create -n "$RESOURCE_GROUP" -l "$LOCATION" --only-show-errors >/dev/null
fi

# Feed answers in deploy.sh's exact prompt order. The password travels only
# through this stdin pipe - it is not on disk and not in any process argument.
{
  printf '%s\n' "$RESOURCE_GROUP" "$FUNCTION_APP" "$STORAGE_ACCOUNT" \
                "$APP_SERVICE_PLAN" "$KEY_VAULT" "$APP_INSIGHTS" "$APP_REGISTRATION"
  if [[ -n "$CA_TENANT" ]]; then
    printf '%s\n' "$CA_TENANT" "$CA_USER" "$CA_PASS"
  else
    printf '%s\n' ""   # single empty line => deploy.sh skips the credential section
  fi
} | bash "$DEPLOY"

unset CA_PASS
echo "run-deploy.sh finished."
