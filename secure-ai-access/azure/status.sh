#!/usr/bin/env bash
# =============================================================================
# status.sh
# Post-deployment health + scan-status check for the CyberArk Secure AI Agents
# Azure scanner. READ-ONLY by default. Reads names from scanner.conf.
#
#   bash status.sh              # health + recent run status (read-only)
#   bash status.sh --run        # ALSO trigger a fresh scan (POST /admin/.../scanner)
#   bash status.sh --hours 48   # widen the Application Insights lookback window
# =============================================================================
set -uo pipefail

DO_RUN=0
HOURS=24
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run)   DO_RUN=1; shift;;
    --hours) HOURS="${2:-24}"; shift 2;;
    -h|--help) echo "Usage: bash status.sh [--run] [--hours N]"; exit 0;;
    *) echo "Unknown argument: $1"; exit 1;;
  esac
done

if [[ -t 1 ]]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; BLU=$'\033[34m'; BLD=$'\033[1m'; RST=$'\033[0m'
else RED=""; GRN=""; YLW=""; BLU=""; BLD=""; RST=""; fi
pass(){ printf "  ${GRN}[ OK ]${RST} %s\n" "$1"; }
warn(){ printf "  ${YLW}[WARN]${RST} %s\n" "$1"; }
fail(){ printf "  ${RED}[FAIL]${RST} %s\n" "$1"; }
section(){ printf "\n${BLD}== %s ==${RST}\n" "$1"; }

# ---- parse scanner.conf (CRLF-safe, no source) ----
CONF_FILE="${SCANNER_CONF:-scanner.conf}"
SUBSCRIPTION_ID=""; RESOURCE_GROUP=""; FUNCTION_APP=""
STORAGE_ACCOUNT=""; KEY_VAULT=""; APP_INSIGHTS=""
[[ -f "$CONF_FILE" ]] || { echo "Missing $CONF_FILE"; exit 1; }
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"; line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  key="${line%%=*}"; val="${line#*=}"; key="${key//[[:space:]]/}"
  val="${val%$'\r'}"; val="${val#"${val%%[![:space:]]*}"}"
  val="${val%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"
  case "$key" in
    SUBSCRIPTION_ID) SUBSCRIPTION_ID="$val";; RESOURCE_GROUP) RESOURCE_GROUP="$val";;
    FUNCTION_APP) FUNCTION_APP="$val";; STORAGE_ACCOUNT) STORAGE_ACCOUNT="$val";;
    KEY_VAULT) KEY_VAULT="$val";; APP_INSIGHTS) APP_INSIGHTS="$val";;
  esac
done < "$CONF_FILE"
command -v az >/dev/null 2>&1 || { echo "Azure CLI (az) not found."; exit 1; }
if [[ -n "$SUBSCRIPTION_ID" ]]; then
  az account set --subscription "$SUBSCRIPTION_ID" 2>/dev/null
else
  echo "WARNING: SUBSCRIPTION_ID empty in $CONF_FILE - reporting on the ACTIVE subscription (may be the wrong one)."
fi
RG="$RESOURCE_GROUP"; FUNC="$FUNCTION_APP"; KV="$KEY_VAULT"; SA="$STORAGE_ACCOUNT"; AI="$APP_INSIGHTS"

printf "${BLD}Subscription:${RST} %s\n" "$(az account show --query '[name,id]' -o tsv 2>/dev/null | tr '\t' ' ')"
printf "${BLD}RG/Func:${RST} %s / %s\n" "$RG" "$FUNC"

# =============================================================================
section "Function App"
# =============================================================================
STATE="$(az functionapp show -g "$RG" -n "$FUNC" --query state -o tsv 2>/dev/null)"
if [[ -z "$STATE" ]]; then
  fail "Function App '$FUNC' not found in RG '$RG' (wrong sub/names, or not deployed)"
  exit 1
fi
[[ "$STATE" == "Running" ]] && pass "Function App state: Running" || warn "Function App state: $STATE"

# the 'scanner' function only exists if the code package was published successfully
FUNCS="$(az functionapp function list -g "$RG" -n "$FUNC" --query "[].name" -o tsv 2>/dev/null | tr -d '\r')"
if grep -qiw "scanner" <<<"$FUNCS"; then
  pass "Function 'scanner' is published"
else
  fail "Function 'scanner' NOT found - the code publish (config-zip) likely did not complete"
  [[ -n "$FUNCS" ]] && echo "        functions present: $(echo "$FUNCS" | tr '\n' ' ')"
fi

# key app settings
SETTINGS="$(az functionapp config appsettings list -g "$RG" -n "$FUNC" --query "[].name" -o tsv 2>/dev/null | tr -d '\r')"
for s in VAULT_NAME SUBSCRIPTION_ID APPLICATIONINSIGHTS_CONNECTION_STRING; do
  grep -qx "$s" <<<"$SETTINGS" && pass "app setting present: $s" || warn "app setting missing: $s"
done

# =============================================================================
section "Identity & storage role"
# =============================================================================
MI="$(az functionapp identity show -g "$RG" -n "$FUNC" --query principalId -o tsv 2>/dev/null)"
if [[ -n "$MI" ]]; then
  pass "System-assigned managed identity present"
  SA_ID="$(az storage account show -g "$RG" -n "$SA" --query id -o tsv 2>/dev/null)"
  if [[ -n "$SA_ID" ]]; then
    ROLES="$(az role assignment list --assignee "$MI" --scope "$SA_ID" --query "[].roleDefinitionName" -o tsv 2>/dev/null | tr -d '\r')"
    grep -qx "Storage Blob Data Contributor" <<<"$ROLES" \
      && pass "MI has 'Storage Blob Data Contributor' on the storage account" \
      || warn "MI is missing the storage blob role (function host storage may fail)"
  fi
else
  warn "No managed identity on the Function App"
fi

# =============================================================================
section "Key Vault secrets (names only - values never shown)"
# =============================================================================
SECRETS="$(az keyvault secret list --vault-name "$KV" --query "[].name" -o tsv 2>/dev/null | tr -d '\r')"
if [[ -z "$SECRETS" ]]; then
  warn "Could not list secrets in '$KV' (no access, or vault not found)"
else
  for s in appregtenantid appregclientid appregclientsecret; do
    grep -qx "$s" <<<"$SECRETS" && pass "secret present: $s" || fail "secret MISSING: $s"
  done
  for s in cyberarktenantname cyberarkusername cyberarkpassword; do
    grep -qx "$s" <<<"$SECRETS" && pass "secret present: $s" \
      || warn "secret missing: $s (set only if you entered service-user creds at deploy)"
  done
fi

# =============================================================================
section "Recent scan activity (Application Insights, last ${HOURS}h)"
# =============================================================================
if ! az extension show -n application-insights >/dev/null 2>&1; then
  warn "az extension 'application-insights' not installed - cannot query run history"
  printf "        ${BLU}fix:${RST} az extension add -n application-insights\n"
else
  Q="union requests, exceptions, traces \
     | where timestamp > ago(${HOURS}h) \
     | order by timestamp desc | take 25 \
     | project timestamp, itemType, name=coalesce(name, operation_Name), resultCode, success, msg=substring(coalesce(message,''),0,80)"
  if OUT="$(az monitor app-insights query --app "$AI" -g "$RG" --analytics-query "$Q" -o table 2>/dev/null)"; then
    if [[ -n "$OUT" ]]; then
      pass "Telemetry found (most recent first):"
      echo "$OUT" | sed 's/^/    /'
    else
      warn "No telemetry in the last ${HOURS}h - scan may not have run yet (it also auto-runs every 12h)"
    fi
  else
    warn "Query failed (telemetry can take a few minutes to appear after the first run)"
  fi
fi

# =============================================================================
section "Trigger a scan"
# =============================================================================
INVOKE_URL="https://${FUNC}.azurewebsites.net/admin/functions/scanner"
if [[ "$DO_RUN" -eq 1 ]]; then
  KEY="$(az functionapp keys list -g "$RG" -n "$FUNC" --query masterKey -o tsv 2>/dev/null)"
  if [[ -z "$KEY" ]]; then
    fail "Could not retrieve function key - cannot trigger"
  else
    echo "  POST $INVOKE_URL"
    ST="$(curl -s -o /dev/null -w "%{http_code}" -X POST "$INVOKE_URL" \
           -H "x-functions-key: $KEY" -H "Content-Type: application/json" -d '{}')"
    unset KEY
    [[ "$ST" == "202" ]] && pass "Scan triggered (HTTP 202 Accepted)" || fail "Trigger returned HTTP $ST"
    echo "  Re-run 'bash status.sh' in a minute to see it under Recent scan activity."
  fi
else
  echo "  (not triggered) to start a scan now:  bash status.sh --run"
fi

# live logs hint
printf "\n${BLD}Live logs:${RST} az webapp log tail -g %s -n %s\n" "$RG" "$FUNC"
