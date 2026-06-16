#!/usr/bin/env bash
# =============================================================================
# preflight.sh
# Pre-deployment checks for the CyberArk "Secure AI Agents" Azure scanner.
# Verifies EVERYTHING deploy.sh needs BEFORE you run it, and tells you exactly
# what is missing and how to fix it.
#
# READ-ONLY by design: it never creates or deletes Azure resources. The only
# write action is optional resource-provider registration, and only after you
# explicitly say "y".
#
# Run from the extracted scanner package folder:
#     bash preflight.sh
# =============================================================================
set -uo pipefail   # deliberately NOT -e: we want every check to run, then summarize.

# ---------- arguments ----------
DO_VALIDATE=0
for a in "$@"; do
  case "$a" in
    --validate) DO_VALIDATE=1;;
    -h|--help) echo "Usage: bash preflight.sh [--validate]"; echo "  --validate   also run an az deployment what-if dry-run (catches policy/quota/template issues)"; exit 0;;
    *) echo "Unknown argument: $a (use --help)"; exit 1;;
  esac
done

# ---------- config (kept in sync with deploy.sh) ----------
LOC="${LOC:-eastus}"
NAME_PREFIX="${NAME_PREFIX:-cyberarkscanner}"
REQUIRED_FILES=("deploy.sh" "main.bicep" "cyberarkscanner-fa.zip")
# Resource providers the bicep needs. Microsoft.Web/Insights are the usual
# culprits behind "resource deployment operation failed" in CSP subscriptions.
REQUIRED_RPS=("Microsoft.Web" "Microsoft.Storage" "Microsoft.KeyVault" "Microsoft.Insights" "Microsoft.OperationalInsights")

# ---------- optional config file: single source of truth for names ----------
# If scanner.conf exists, names are read from it and NOT prompted for.
# Parsed safely (no 'source', so no code execution) and CRLF-proof (Windows).
SUBSCRIPTION_ID=""; LOCATION=""; RESOURCE_GROUP=""; FUNCTION_APP=""
STORAGE_ACCOUNT=""; APP_SERVICE_PLAN=""; KEY_VAULT=""; APP_INSIGHTS=""; APP_REGISTRATION=""
CONF_FILE="${SCANNER_CONF:-scanner.conf}"
CONF_LOADED=0
load_conf(){
  local file="$1" line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"                         # strip CR (Windows line endings)
    line="${line#"${line%%[![:space:]]*}"}"      # left-trim
    [[ -z "$line" || "$line" == \#* ]] && continue
    key="${line%%=*}"; val="${line#*=}"
    key="${key//[[:space:]]/}"
    val="${val%$'\r'}"; val="${val#"${val%%[![:space:]]*}"}"
    val="${val%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"   # strip quotes
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
  done < "$file"
}
if [[ -f "$CONF_FILE" ]]; then load_conf "$CONF_FILE"; CONF_LOADED=1; fi
[[ -n "$LOCATION" ]] && LOC="$LOCATION"

# ---------- pretty output (ASCII only, safe in Git Bash / MINGW64) ----------
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; BLU=$'\033[34m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=""; GRN=""; YLW=""; BLU=""; BLD=""; RST=""
fi
FAIL=0; WARN=0
pass(){     printf "  ${GRN}[ PASS ]${RST} %s\n" "$1"; }
warn(){     printf "  ${YLW}[ WARN ]${RST} %s\n" "$1"; WARN=$((WARN+1)); }
fail(){     printf "  ${RED}[ FAIL ]${RST} %s\n" "$1"; FAIL=$((FAIL+1)); }
fixhint(){  printf "           ${BLU}fix:${RST} %s\n" "$1"; }
section(){  printf "\n${BLD}== %s ==${RST}\n" "$1"; }

# =============================================================================
section "Tooling"
# =============================================================================
AZ_OK=0
if command -v az >/dev/null 2>&1; then
  AZ_VER="$(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
  pass "Azure CLI installed (${AZ_VER:-unknown version})"
  AZ_OK=1
else
  fail "Azure CLI (az) not found"
  fixhint "winget install -e --id Microsoft.AzureCLI    (or https://aka.ms/installazurecliwindows)"
fi

if [[ "$AZ_OK" -eq 1 ]]; then
  if az bicep version >/dev/null 2>&1; then
    pass "Bicep CLI available"
  else
    warn "Bicep not pre-installed (az auto-installs it on first deploy, but pre-installing avoids surprises)"
    fixhint "az bicep install"
  fi
fi

# If az is missing, the rest of the checks can't run.
if [[ "$AZ_OK" -eq 0 ]]; then
  section "Summary"
  printf "  ${RED}Azure CLI is required before any other check can run.${RST}\n"
  exit 1
fi

# =============================================================================
section "Configuration source"
# =============================================================================
if [[ "$CONF_LOADED" -eq 1 ]]; then
  pass "Loaded settings from '$CONF_FILE' - names are validated from the file, not prompted"
else
  warn "No '$CONF_FILE' found - the script will PROMPT for names to validate"
  fixhint "create '$CONF_FILE' (see scanner.conf.example) to set names + subscription once and stop retyping"
fi

# =============================================================================
section "Authentication"
# =============================================================================
LOGGED_IN=0
if az account show >/dev/null 2>&1; then
  LOGGED_IN=1
  UPN="$(az account show --query user.name -o tsv 2>/dev/null)"
  pass "Signed in as: ${UPN}"
else
  fail "Not signed in to Azure"
  fixhint "az login    (interactive sign-in satisfies most Conditional Access; from a managed device if CA blocks Cloud Shell)"
fi

if [[ "$LOGGED_IN" -eq 0 ]]; then
  section "Summary"
  printf "  ${RED}Sign in first, then re-run preflight.${RST}\n"
  exit 1
fi

# =============================================================================
section "Runtime environment & token issuance (Conditional Access)"
# =============================================================================
# This is the part that forced the Cloud Shell -> Windows detour. deploy.sh needs
# tokens for THREE different audiences, and a Conditional Access policy can block
# any one of them independently:
#   - ARM          (management.azure.com)  -> the infrastructure deployment
#   - Graph        (graph.microsoft.com)    -> app registration + admin consent
#   - App Service  (appservice.azure.com)   -> the 'config-zip' code publish (Kudu/SCM)
# The App Service token is the sneaky one: normal az use never requests it, so a
# CA block on it only surfaces mid-deploy. We force-request all three now.

RUNENV="Linux/macOS native"
if [[ -n "${AZUREPS_HOST_ENVIRONMENT:-}" || -n "${ACC_CLOUD:-}" ]]; then
  RUNENV="Azure Cloud Shell"
elif [[ "${MSYSTEM:-}" == MINGW* || "${OSTYPE:-}" == msys ]]; then
  RUNENV="Git Bash (MINGW) on Windows"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  RUNENV="WSL on Windows"
fi
printf "  Running in: ${BLD}%s${RST}\n" "$RUNENV"
if [[ "$RUNENV" == "Azure Cloud Shell" ]]; then
  warn "Cloud Shell runs from a Microsoft sandbox host; strict Conditional Access often blocks it (AADSTS53003)."
  fixhint "If a token test below fails: run from a managed/compliant device, or apply a documented CA exclusion."
fi

test_token(){
  # $1 label   $2 resource   $3 re-login scope hint
  local label="$1" resource="$2" hintscope="$3" err
  if err="$(az account get-access-token --resource "$resource" -o none 2>&1)"; then
    pass "Token OK: $label"
  elif grep -qiE "AADSTS53003|Conditional Access|access has been blocked" <<<"$err"; then
    fail "Token BLOCKED by Conditional Access: $label"
    fixhint "Managed/compliant device or CA exclusion. Re-auth this scope: az login --scope \"$hintscope\""
  else
    warn "Could not acquire token: $label - $(printf '%s' "$err" | tr '\n' ' ' | cut -c1-110)"
    fixhint "az login --scope \"$hintscope\""
  fi
}
test_token "ARM (deployment)"                  "https://management.azure.com/"  "https://management.azure.com/.default"
test_token "Microsoft Graph (app reg)"         "https://graph.microsoft.com/"   "https://graph.microsoft.com/.default"
test_token "App Service / Kudu (code publish)" "https://appservice.azure.com/"  "https://appservice.azure.com/.default"

# =============================================================================
section "Subscription context"
# =============================================================================
if [[ -n "$SUBSCRIPTION_ID" ]]; then
  if az account set --subscription "$SUBSCRIPTION_ID" 2>/dev/null; then
    pass "Subscription selected from config by ID: $SUBSCRIPTION_ID"
  else
    fail "Config SUBSCRIPTION_ID '$SUBSCRIPTION_ID' not found / no access"
    fixhint "check the ID in '$CONF_FILE' (use 'az account list -o table' to find it)"
  fi
fi
SUB_ID="$(az account show --query id -o tsv)"
SUB_NAME="$(az account show --query name -o tsv)"
printf "  Active subscription: ${BLD}%s${RST} (%s)\n" "$SUB_NAME" "$SUB_ID"

# The trap that cost the whole last session: multiple subs with the SAME name.
DUP="$(az account list --query "[?name=='$SUB_NAME'] | length(@)" -o tsv 2>/dev/null)"
if [[ "${DUP:-1}" -gt 1 ]]; then
  warn "There are ${DUP} subscriptions named '${SUB_NAME}'. Confirm THIS id is the intended target."
  fixhint "set SUBSCRIPTION_ID (by ID) in '$CONF_FILE', or: az account set --subscription <ID>"
fi

if [[ -n "$SUBSCRIPTION_ID" ]]; then
  if [[ "$SUB_ID" == "$SUBSCRIPTION_ID" ]]; then
    pass "Active subscription matches config - no manual confirmation needed"
  else
    fail "Active subscription ($SUB_ID) does NOT match config ($SUBSCRIPTION_ID)"
  fi
else
  echo "  All subscriptions visible to you:"
  az account list --query "[].{name:name, id:id, isDefault:isDefault}" -o table | sed 's/^/    /'
  read -rp "  Is ${SUB_NAME} (${SUB_ID}) the correct target subscription? [y/N]: " SUBOK
  if [[ ! "$SUBOK" =~ ^[Yy]$ ]]; then
    fail "Wrong subscription selected"
    fixhint "set SUBSCRIPTION_ID in '$CONF_FILE', or: az account set --subscription <ID>"
  fi
fi

# =============================================================================
section "Permissions (Azure RBAC)"
# =============================================================================
# The bicep creates TWO 'Storage Blob Data Contributor' role assignments on the
# storage account (one for the function's managed identity, one for the deployer
# so it can upload the code package). Those need Microsoft.Authorization/
# roleAssignments/write, which Contributor does NOT have. (The Key Vault uses
# ACCESS POLICIES, not RBAC, so the KV grant itself is fine with Contributor.)
# Net minimum to deploy: Owner  OR  (Contributor + User Access Administrator).
USER_TYPE="$(az account show --query user.type -o tsv)"
if [[ "$USER_TYPE" == "user" ]]; then
  OID="$(az ad signed-in-user show --query id -o tsv 2>/dev/null)"
else
  OID="$(az ad sp show --id "$UPN" --query id -o tsv 2>/dev/null)"
fi

ROLES="$(az role assignment list --assignee "${OID:-none}" --scope "/subscriptions/$SUB_ID" --include-inherited --query "[].roleDefinitionName" -o tsv 2>/dev/null | tr -d '\r')"
if grep -qx "Owner" <<<"$ROLES"; then
  pass "RBAC: Owner on subscription (covers resource creation + the bicep role assignment)"
elif grep -qx "Contributor" <<<"$ROLES" && grep -qx "User Access Administrator" <<<"$ROLES"; then
  pass "RBAC: Contributor + User Access Administrator (sufficient)"
elif grep -qx "Contributor" <<<"$ROLES"; then
  fail "RBAC: Contributor only. The bicep does an internal role assignment that Contributor cannot perform."
  fixhint "Grant 'Owner' (preferred) or add 'User Access Administrator' at the subscription or target RG scope"
else
  warn "RBAC: no active Owner/Contributor found at this scope."
  fixhint "Assignment may be via a group or PIM (eligible != active, and not shown here). If PIM: ACTIVATE the role first. Otherwise assign Owner."
fi

# =============================================================================
section "Permissions (Entra / Microsoft Graph)"
# =============================================================================
# deploy.sh creates an app registration, requests Application.Read.All, and grants
# ADMIN CONSENT. Admin consent requires Global Administrator or Privileged Role
# Administrator. We try to read your directory roles; the Graph call itself can be
# blocked by Conditional Access (that is what bit Cloud Shell), so treat failure
# as "unverified", not a hard fail.
DIRROLES="$(az rest --method GET \
  --uri "https://graph.microsoft.com/v1.0/me/memberOf/microsoft.graph.directoryRole?\$select=displayName" \
  --query "value[].displayName" -o tsv 2>/dev/null)"
if [[ -z "$DIRROLES" ]]; then
  warn "Could not read your Entra directory roles (Graph token may be blocked by Conditional Access, or no directory roles)."
  fixhint "Admin consent for Application.Read.All needs Global Administrator or Privileged Role Administrator."
elif grep -qiE "Global Administrator|Privileged Role Administrator" <<<"$DIRROLES"; then
  pass "Entra: you hold a role that can grant admin consent (Global Admin / Privileged Role Admin)"
else
  fail "Entra: none of your directory roles can grant admin consent for Application.Read.All"
  fixhint "Use an account with Global Administrator or Privileged Role Administrator for the deploy"
fi

# =============================================================================
section "Resource providers"
# =============================================================================
MISSING_RPS=()
for rp in "${REQUIRED_RPS[@]}"; do
  state="$(az provider show -n "$rp" --query registrationState -o tsv 2>/dev/null)"
  if [[ "$state" == "Registered" ]]; then
    pass "RP ${rp}: Registered"
  else
    fail "RP ${rp}: ${state:-NotFound}"
    fixhint "az provider register --namespace ${rp}"
    MISSING_RPS+=("$rp")
  fi
done
if [[ "${#MISSING_RPS[@]}" -gt 0 ]]; then
  read -rp "  Register the ${#MISSING_RPS[@]} missing provider(s) now? [y/N]: " REGOK
  if [[ "$REGOK" =~ ^[Yy]$ ]]; then
    for rp in "${MISSING_RPS[@]}"; do
      echo "  registering $rp ..."
      az provider register --namespace "$rp" >/dev/null 2>&1 \
        && echo "    requested (registration is async; it becomes 'Registered' within a few minutes)" \
        || echo "    failed to request registration for $rp"
    done
    warn "Registration is asynchronous. Re-run preflight in a few minutes to confirm all show 'Registered'."
  fi
fi

# =============================================================================
section "Hosting plan availability (Flex Consumption)"
# =============================================================================
# The bicep plan is sku FC1 / tier FlexConsumption (kind functionapp,linux).
# Flex Consumption is only offered in a SUBSET of regions - this is the most
# likely cause of "resource deployment operation failed" when the rest looks ok.
norm(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'; }
# If the RG already exists, its region is the one that counts (RG location is
# immutable) - derive LOC from it so we validate the ACTUAL deploy region.
if az group show -n "$RESOURCE_GROUP" >/dev/null 2>&1; then
  RG_LOC="$(az group show -n "$RESOURCE_GROUP" --query location -o tsv 2>/dev/null)"
  if [[ -n "$RG_LOC" ]]; then
    if [[ "$(norm "$RG_LOC")" != "$(norm "$LOC")" ]]; then
      warn "scanner.conf LOCATION='$LOC' but existing RG '$RESOURCE_GROUP' is in '$RG_LOC' - using the RG's region (immutable)."
    else
      pass "Region derived from existing RG: $RG_LOC"
    fi
    LOC="$RG_LOC"
  fi
fi
TARGET_LOC="$(norm "$LOC")"
FLEX_LOCS="$(az functionapp list-flexconsumption-locations --query "[].name" -o tsv 2>/dev/null)"
if [[ -z "$FLEX_LOCS" ]]; then
  warn "Could not retrieve Flex Consumption regions (older az, or transient). Verify manually."
  fixhint "az functionapp list-flexconsumption-locations -o table   (region must contain '$LOC')"
else
  FLEX_MATCH=0
  while IFS= read -r r; do
    [[ "$(norm "$r")" == "$TARGET_LOC" ]] && { FLEX_MATCH=1; break; }
  done <<<"$FLEX_LOCS"
  if [[ "$FLEX_MATCH" -eq 1 ]]; then
    pass "Flex Consumption (FC1) is available in '$LOC'"
  else
    fail "Flex Consumption (FC1) is NOT available in '$LOC' - the serverfarm (plan) will fail to create"
    fixhint "choose a supported region in $CONF_FILE (LOCATION). See: az functionapp list-flexconsumption-locations -o table"
  fi
fi
# App Insights note: the bicep creates a CLASSIC component (IngestionMode=ApplicationInsights,
# no workspace). Classic creation is retired in many subscriptions; Azure may auto-provision a
# default Log Analytics workspace - which is why Microsoft.OperationalInsights must be registered
# (checked above). If the deployment fails specifically on the Insights component, this is why.
echo "  note: App Insights is created in classic mode; a default Log Analytics workspace may be auto-created."

# =============================================================================
section "Package files"
# =============================================================================
for f in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    pass "Present: $f"
  else
    fail "Missing: $f"
    fixhint "Run from the extracted scanner package; download the Microsoft Azure scanner from the CyberArk Marketplace"
  fi
done

# =============================================================================
section "Name validation (storage + function app are GLOBAL namespaces)"
# =============================================================================
# Both must be globally unique. Validating now avoids a failed deploy mid-run.
# Storage + Function App + Key Vault live in GLOBAL namespaces -> must be globally
# unique. When scanner.conf is loaded these come from the file (no prompts).
SA="${STORAGE_ACCOUNT}"
[[ -z "$SA" ]] && read -rp "  Storage Account name to validate (Enter to skip): " SA
if [[ -n "$SA" ]]; then
  if [[ "$SA" =~ ^[a-z0-9]{3,24}$ ]]; then
    avail="$(az storage account check-name --name "$SA" --query nameAvailable -o tsv 2>/dev/null)"
    if [[ "$avail" == "true" ]]; then
      pass "Storage '$SA' valid and globally available"
    else
      fail "Storage '$SA' is taken globally"
      fixhint "pick another (3-24 chars, lowercase letters/digits only)"
    fi
  else
    fail "Storage '$SA' invalid format"
    fixhint "3-24 chars, lowercase letters and digits only, NO hyphens (e.g. cyberarkscanstg01)"
  fi
fi

FN="${FUNCTION_APP}"
[[ -z "$FN" ]] && read -rp "  Function App name to validate (Enter to skip): " FN
if [[ -n "$FN" ]]; then
  if [[ "$FN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,58}[a-zA-Z0-9])?$ ]]; then
    res="$(az rest --method POST \
      --uri "https://management.azure.com/subscriptions/$SUB_ID/providers/Microsoft.Web/checkNameAvailability?api-version=2023-12-01" \
      --body "{\"name\":\"$FN\",\"type\":\"Microsoft.Web/sites\"}" \
      --query nameAvailable -o tsv 2>/dev/null)"
    if [[ "$res" == "true" ]]; then
      pass "Function App '$FN' available globally"
    else
      fail "Function App '$FN' is taken globally (azurewebsites.net) or soft-deleted"
      fixhint "pick a unique name, e.g. ${FN}-$(date +%s | tail -c 4)"
    fi
  else
    fail "Function App '$FN' invalid format"
    fixhint "2-60 chars, alphanumeric and hyphens, no leading/trailing hyphen"
  fi
fi

# Key Vault name is ALSO global (<name>.vault.azure.net): format + soft-delete flag.
if [[ -n "$KEY_VAULT" ]]; then
  if [[ "$KEY_VAULT" =~ ^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$ && "$KEY_VAULT" != *--* ]]; then
    pass "Key Vault '$KEY_VAULT' format OK (note: global name; a soft-deleted vault with this name blocks reuse - purge it)"
  else
    fail "Key Vault '$KEY_VAULT' invalid format"
    fixhint "3-24 chars, start with a letter, alphanumeric/hyphens, no consecutive hyphens"
  fi
fi

# Remaining names are RG-scoped: light sanity check only.
check_simple(){ # $1 label  $2 value
  [[ -z "$2" ]] && return 0
  if [[ "$2" =~ ^[a-zA-Z0-9._\(\)-]{1,80}$ ]]; then
    pass "$1 '$2' format OK"
  else
    warn "$1 '$2' has unusual characters - double-check Azure naming rules"
  fi
}
check_simple "Resource group"      "$RESOURCE_GROUP"
check_simple "App Service plan"     "$APP_SERVICE_PLAN"
check_simple "Application Insights" "$APP_INSIGHTS"
check_simple "App Registration"     "$APP_REGISTRATION"

# =============================================================================
section "CyberArk Identity prerequisites (manual - cannot be auto-checked)"
# =============================================================================
echo "  These live in CyberArk Identity Administration, not Azure. Confirm before deploy:"
echo "    1. Service user created (Is OAuth confidential client + Is Service User)."
echo "    2. Added to role 'Discovery & Context Azure Communication'."
echo "    3. Have ready for the deploy.sh prompts: tenant subdomain, username, password."
echo "  Without these, the deploy succeeds but the scan has nothing to authenticate with."

# =============================================================================
if [[ "$DO_VALIDATE" -eq 1 ]]; then
section "Deployment dry-run (what-if)"
# =============================================================================
# Runs the REAL bicep through what-if. This is the only step that surfaces
# Azure Policy / deny-assignment blocks, quota limits, and template errors -
# WITHOUT creating any resources. Needs the target RG to exist (what-if is
# RG-scoped); we offer to create an empty RG just for the preview.
  MISSING_PARAMS=""
  for pair in "RESOURCE_GROUP:$RESOURCE_GROUP" "FUNCTION_APP:$FUNCTION_APP" \
              "STORAGE_ACCOUNT:$STORAGE_ACCOUNT" "APP_SERVICE_PLAN:$APP_SERVICE_PLAN" \
              "KEY_VAULT:$KEY_VAULT" "APP_INSIGHTS:$APP_INSIGHTS"; do
    [[ -z "${pair#*:}" ]] && MISSING_PARAMS="$MISSING_PARAMS ${pair%%:*}"
  done

  if [[ ! -f main.bicep ]]; then
    fail "what-if requested but 'main.bicep' is not in this folder"
  elif [[ -n "$MISSING_PARAMS" ]]; then
    warn "Skipping what-if - these must be set in $CONF_FILE:$MISSING_PARAMS"
  elif [[ -z "${OID:-}" ]]; then
    warn "Skipping what-if - could not resolve your object id (deployerObjectId) earlier"
  else
    RG_TEMP=0
    if ! az group show -n "$RESOURCE_GROUP" >/dev/null 2>&1; then
      warn "RG '$RESOURCE_GROUP' does not exist; what-if is RG-scoped and needs it."
      read -rp "  Create a TEMPORARY empty RG '$RESOURCE_GROUP' in '$LOC' for the preview (removed afterwards)? [y/N]: " MKRG
      if [[ "$MKRG" =~ ^[Yy]$ ]]; then
        if az group create -n "$RESOURCE_GROUP" -l "$LOC" --only-show-errors >/dev/null 2>&1; then
          pass "Temporary RG created for the preview"; RG_TEMP=1
        else
          fail "Could not create RG (policy on allowed-locations? check the error)"
        fi
      fi
    fi
    if az group show -n "$RESOURCE_GROUP" >/dev/null 2>&1; then
      echo "  Running what-if (no resources are created)..."
      if az deployment group what-if \
            -g "$RESOURCE_GROUP" -f main.bicep \
            -p funcName="$FUNCTION_APP" deployerObjectId="$OID" saName="$STORAGE_ACCOUNT" \
               planName="$APP_SERVICE_PLAN" kvName="$KEY_VAULT" aiName="$APP_INSIGHTS" \
            --only-show-errors; then
        pass "what-if completed - review the change preview above (a clean preview = ARM should accept it)"
      else
        fail "what-if reported errors above (policy / quota / template) - fix before deploying"
      fi
    fi
    # Leave no trace: if WE created the RG only for the preview and it is still
    # empty, remove it. (Deploying into a pre-existing empty RG is fine either way -
    # az group create is idempotent - but preflight should not leave state behind.)
    if [[ "$RG_TEMP" -eq 1 ]]; then
      cnt="$(az resource list -g "$RESOURCE_GROUP" --query "length(@)" -o tsv 2>/dev/null)"
      if [[ "${cnt:-0}" -eq 0 ]]; then
        az group delete -n "$RESOURCE_GROUP" --yes --no-wait >/dev/null 2>&1 \
          && echo "  removed the temporary preview RG (preflight leaves nothing behind)"
      else
        warn "Temporary RG is not empty (what-if shouldn't create resources) - left it for you to inspect."
      fi
    fi
  fi
fi

# =============================================================================
section "Summary"
# =============================================================================
printf "  FAIL: %s    WARN: %s\n" "$FAIL" "$WARN"
if [[ "$FAIL" -gt 0 ]]; then
  printf "  ${RED}NOT READY${RST} - resolve the FAIL items above before running ./deploy.sh\n"
  exit 1
else
  if [[ "$WARN" -gt 0 ]]; then
    printf "  ${YLW}READY (with warnings)${RST} - review WARNs, then run ./deploy.sh\n"
  else
    printf "  ${GRN}READY${RST} - you can run ./deploy.sh\n"
  fi
  exit 0
fi
