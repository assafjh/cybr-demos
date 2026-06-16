#!/usr/bin/env bash
set -uo pipefail
# =============================================================================
# discover.sh
# Find leftover scanner resources across ALL subscriptions you can see.
# READ-ONLY - creates and deletes nothing. Names come from scanner.conf.
# Run this before cleanup: it tells you which subscription(s) to point
# uninstall.sh at, and prints the ready-to-run commands.
#
#   bash discover.sh
# =============================================================================

if [[ -t 1 ]]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; BLU=$'\033[34m'; BLD=$'\033[1m'; RST=$'\033[0m'
else RED=""; GRN=""; YLW=""; BLU=""; BLD=""; RST=""; fi

# ---- parse scanner.conf (CRLF-safe, no source) ----
CONF_FILE="${SCANNER_CONF:-scanner.conf}"
RESOURCE_GROUP=""; FUNCTION_APP=""; STORAGE_ACCOUNT=""; KEY_VAULT=""; APP_REGISTRATION=""; NAME_PREFIX=""
[[ -f "$CONF_FILE" ]] || { echo "Missing $CONF_FILE"; exit 1; }
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"; line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  key="${line%%=*}"; val="${line#*=}"; key="${key//[[:space:]]/}"
  val="${val%$'\r'}"; val="${val#"${val%%[![:space:]]*}"}"
  val="${val%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"
  case "$key" in
    RESOURCE_GROUP)   RESOURCE_GROUP="$val";;
    FUNCTION_APP)     FUNCTION_APP="$val";;
    STORAGE_ACCOUNT)  STORAGE_ACCOUNT="$val";;
    KEY_VAULT)        KEY_VAULT="$val";;
    APP_REGISTRATION) APP_REGISTRATION="$val";;
    NAME_PREFIX)      NAME_PREFIX="$val";;
  esac
done < "$CONF_FILE"

command -v az >/dev/null 2>&1 || { echo "Azure CLI (az) not found."; exit 1; }
az account show >/dev/null 2>&1 || { echo "Not signed in. Run: az login"; exit 1; }
[[ -n "$RESOURCE_GROUP" ]] || { echo "RESOURCE_GROUP not set in $CONF_FILE"; exit 1; }

# restore the caller's active subscription on exit (we switch around below)
ORIG_SUB="$(az account show --query id -o tsv 2>/dev/null || true)"
restore(){ [[ -n "$ORIG_SUB" ]] && az account set --subscription "$ORIG_SUB" >/dev/null 2>&1 || true; }
trap restore EXIT

printf "${BLD}Looking for: RG='%s', func='%s', KV='%s', app-reg='%s'${RST}\n" \
  "$RESOURCE_GROUP" "$FUNCTION_APP" "$KEY_VAULT" "$APP_REGISTRATION"
printf "${YLW}Note:${RST} results depend on your RBAC. A subscription you can't act on shows '(no access)',\n"
printf "      and resources you can't read won't appear - set up permissions BEFORE relying on this.\n"

RG_SUBS=()
SUBS="$(az account list --query "[].id" -o tsv | tr -d '\r')"

for s in $SUBS; do
  sname="$(az account list --query "[?id=='$s'].name | [0]" -o tsv 2>/dev/null | tr -d '\r')"
  printf "\n${BLD}== %s (%s) ==${RST}\n" "${sname:-?}" "$s"
  if ! az account set --subscription "$s" >/dev/null 2>&1; then
    printf "  ${YLW}(no access - not in your tenant scope, or no RBAC on this subscription)${RST}\n"; continue
  fi

  # Resource group + its contents
  if az group show -n "$RESOURCE_GROUP" >/dev/null 2>&1; then
    printf "  ${GRN}RG '%s' FOUND${RST}\n" "$RESOURCE_GROUP"
    az resource list -g "$RESOURCE_GROUP" --query "[].{name:name,type:type}" -o table 2>/dev/null | sed 's/^/    /'
    RG_SUBS+=("$s")
  else
    echo "  RG '$RESOURCE_GROUP': not here"
  fi

  # Stray function app(s) - match by PREFIX if set (catches drifted names like
  # <prefix>-fa, <prefix>-fa-v2), else fall back to the exact configured name.
  if [[ -n "$NAME_PREFIX" ]]; then
    fa_hits="$(az functionapp list --query "[?starts_with(name,'$NAME_PREFIX')].{n:name,rg:resourceGroup}" -o tsv 2>/dev/null | tr -d '\r')"
    [[ -n "$fa_hits" ]] && { printf "  ${YLW}function app(s) with prefix '%s*':${RST}\n" "$NAME_PREFIX"; echo "$fa_hits" | sed 's/^/      /'; }
  elif [[ -n "$FUNCTION_APP" ]]; then
    fa_rg="$(az functionapp list --query "[?name=='$FUNCTION_APP'].resourceGroup | [0]" -o tsv 2>/dev/null | tr -d '\r')"
    [[ -n "$fa_rg" ]] && printf "  ${YLW}function app '%s' present in RG: %s${RST}\n" "$FUNCTION_APP" "$fa_rg"
  fi

  # Soft-deleted Key Vault(s) - prefix if set, else exact name.
  if [[ -n "$NAME_PREFIX" ]]; then
    dk="$(az keyvault list-deleted --query "[?starts_with(name,'$NAME_PREFIX')].name" -o tsv 2>/dev/null | tr -d '\r')"
    [[ -n "$dk" ]] && { printf "  ${YLW}soft-deleted Key Vault(s) with prefix '%s*' (name reserved ~90d):${RST}\n" "$NAME_PREFIX"; echo "$dk" | sed 's/^/      /'; }
  elif [[ -n "$KEY_VAULT" ]]; then
    dk="$(az keyvault list-deleted --query "[?name=='$KEY_VAULT'].name | [0]" -o tsv 2>/dev/null)"
    [[ -n "$dk" ]] && printf "  ${YLW}Key Vault '%s' is SOFT-DELETED here (name reserved ~90d)${RST}\n" "$KEY_VAULT"
  fi
done

# Tenant-level app registration(s) - prefix sweep if set (catches renamed ones),
# else the exact configured name.
printf "\n${BLD}== App registration (tenant-level) ==${RST}\n"
if [[ -n "$NAME_PREFIX" ]]; then
  ar="$(az ad app list --filter "startswith(displayName,'$NAME_PREFIX')" --query "[].{name:displayName,appId:appId,objectId:id}" -o table 2>/dev/null)"
elif [[ -n "$APP_REGISTRATION" ]]; then
  ar="$(az ad app list --display-name "$APP_REGISTRATION" --query "[].{name:displayName,appId:appId,objectId:id}" -o table 2>/dev/null)"
else
  ar=""
fi
if [[ -n "$ar" ]]; then echo "$ar" | sed 's/^/  /'; else echo "  none found"; fi

# Summary + ready-to-run cleanup commands
printf "\n${BLD}== Summary ==${RST}\n"
if [[ "${#RG_SUBS[@]}" -eq 0 ]]; then
  printf "  ${GRN}No '%s' found in any subscription - nothing to clean.${RST}\n" "$RESOURCE_GROUP"
else
  printf "  RG found in %s subscription(s). To remove (dry-run first, then execute):\n\n" "${#RG_SUBS[@]}"
  for s in "${RG_SUBS[@]}"; do
    printf "    ${BLU}# subscription %s${RST}\n" "$s"
    printf "    bash uninstall.sh --subscription %s --rg %s\n" "$s" "$RESOURCE_GROUP"
    printf "    bash uninstall.sh --subscription %s --rg %s --app-name %s --purge-kv --yes\n\n" \
      "$s" "$RESOURCE_GROUP" "${APP_REGISTRATION:-<APP_REGISTRATION>}"
  done
fi
