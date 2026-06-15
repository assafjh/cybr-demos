#!/usr/bin/env bash
# =============================================================================
# uninstall.sh
# Guarded uninstaller for the CyberArk "Secure AI Agents" Azure scanner.
#
# SAFE BY DEFAULT: it inspects and prints a deletion PLAN but deletes NOTHING
# unless you pass --yes. Even with --yes it makes you type the resource-group
# name to confirm, and treats the app registration (tenant-level) as a
# separate, explicit decision.
#
# Examples:
#   bash uninstall.sh --rg cyberark-agents-scanner                 # dry-run plan
#   bash uninstall.sh --rg cyberark-agents-scanner --subscription <ID>
#   bash uninstall.sh --rg cyberark-agents-scanner --app-name cyberarkscanner-app --yes
#   bash uninstall.sh --rg cyberark-agents-scanner --app-id <APPID> --purge-kv --yes
# =============================================================================
set -uo pipefail

RG=""
APP_NAME=""
APP_ID=""
ASSUME_SUB=""
DRYRUN=1
PURGE_KV=0

if [[ -t 1 ]]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=""; GRN=""; YLW=""; BLD=""; RST=""
fi

usage(){ cat <<EOF
Usage: bash uninstall.sh --rg <RESOURCE_GROUP> [options]

Required:
  --rg NAME            Resource group that deploy.sh created.

App registration (optional, recommended - choose one):
  --app-name NAME      App registration display name (e.g. cyberarkscanner-app).
  --app-id APPID       App registration appId or objectId.

Options:
  --subscription ID    Subscription to operate in. STRONGLY recommended - selecting
                       by ID avoids deleting from the wrong same-named subscription.
  --purge-kv           After RG deletion, purge the soft-deleted Key Vault so its
                       name is freed immediately (otherwise reserved ~90 days).
  --yes                Actually execute. WITHOUT this, the script is a dry-run.
  -h, --help           Show this help.

By default NOTHING is deleted. Review the plan, then re-run with --yes.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rg)           RG="${2:-}"; shift 2;;
    --app-name)     APP_NAME="${2:-}"; shift 2;;
    --app-id)       APP_ID="${2:-}"; shift 2;;
    --subscription) ASSUME_SUB="${2:-}"; shift 2;;
    --purge-kv)     PURGE_KV=1; shift;;
    --yes)          DRYRUN=0; shift;;
    -h|--help)      usage; exit 0;;
    *) echo "Unknown argument: $1"; echo; usage; exit 1;;
  esac
done

command -v az >/dev/null 2>&1 || { echo "Azure CLI (az) not found."; exit 1; }
[[ -n "$RG" ]] || { echo "${RED}--rg is required.${RST}"; echo; usage; exit 1; }
az account show >/dev/null 2>&1 || { echo "Not signed in. Run: az login"; exit 1; }

# ---------- subscription guardrail ----------
if [[ -n "$ASSUME_SUB" ]]; then
  az account set --subscription "$ASSUME_SUB" || { echo "Could not switch to subscription $ASSUME_SUB"; exit 1; }
fi
SUB_ID="$(az account show --query id -o tsv)"
SUB_NAME="$(az account show --query name -o tsv)"
printf "${BLD}Subscription:${RST} %s (%s)\n" "$SUB_NAME" "$SUB_ID"
DUP="$(az account list --query "[?name=='$SUB_NAME'] | length(@)" -o tsv 2>/dev/null)"
if [[ "${DUP:-1}" -gt 1 ]]; then
  printf "${YLW}WARNING:${RST} %s subscriptions share the name '%s'. Confirm this ID is the right one before deleting.\n" "$DUP" "$SUB_NAME"
fi

# ---------- existence check ----------
if ! az group show -n "$RG" >/dev/null 2>&1; then
  echo "${RED}Resource group '$RG' not found in this subscription.${RST} Nothing to do (check the subscription / RG name)."
  exit 1
fi

# ---------- build the plan ----------
printf "\n${BLD}== Deletion plan ==${RST}\n"
echo "Resources in RG '$RG' that WILL be deleted:"
az resource list -g "$RG" --query "[].{name:name, type:type, location:location}" -o table | sed 's/^/  /'

# Key Vault soft-delete awareness
KVS="$(az keyvault list -g "$RG" --query "[].name" -o tsv 2>/dev/null)"
if [[ -n "$KVS" ]]; then
  printf "\n${YLW}Key Vault note:${RST} the RG contains vault(s): %s\n" "$(echo "$KVS" | tr '\n' ' ')"
  echo "  Deleting the RG SOFT-DELETES the vault; the name stays reserved (~90 days) and a"
  echo "  redeploy reusing the same KV name can fail until it is purged or recovered."
  if [[ "$PURGE_KV" -eq 1 ]]; then
    echo "  --purge-kv set: each vault will be purged after RG deletion so the name is freed."
  else
    echo "  (pass --purge-kv to free the name immediately.)"
  fi
fi

# App registration resolution
if [[ -z "$APP_ID" && -n "$APP_NAME" ]]; then
  APP_ID="$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>/dev/null)"
fi
if [[ -n "$APP_ID" ]]; then
  printf "\n${YLW}App registration (TENANT-level, not scoped to this RG):${RST}\n"
  az ad app show --id "$APP_ID" --query "{displayName:displayName, appId:appId}" -o table 2>/dev/null | sed 's/^/  /' \
    || echo "  (could not read app $APP_ID - check the id/name)"
else
  printf "\n${YLW}App registration:${RST} none specified -> it will be LEFT IN PLACE.\n"
  echo "  Pass --app-name or --app-id to include it in the cleanup."
fi

# ---------- dry-run gate ----------
if [[ "$DRYRUN" -eq 1 ]]; then
  printf "\n${GRN}DRY-RUN:${RST} nothing was deleted. Re-run with ${BLD}--yes${RST} to execute.\n"
  exit 0
fi

# ---------- typed confirmation ----------
printf "\n${RED}This will permanently delete the resource group and everything above.${RST}\n"
read -rp "Type the resource group name '$RG' to confirm: " CONFIRM
if [[ "$CONFIRM" != "$RG" ]]; then
  echo "Name mismatch. Aborting - nothing deleted."
  exit 1
fi

# ---------- execute ----------
echo "Deleting resource group '$RG' ..."
if az group delete -n "$RG" --yes; then
  echo "${GRN}Resource group deleted.${RST}"
else
  echo "${RED}Resource group deletion failed.${RST}"
  exit 1
fi

if [[ -n "$KVS" && "$PURGE_KV" -eq 1 ]]; then
  for kv in $KVS; do
    echo "Purging soft-deleted Key Vault '$kv' ..."
    if az keyvault purge --name "$kv" >/dev/null 2>&1; then
      echo "  purged $kv (name freed)"
    else
      echo "  ${YLW}could not purge $kv${RST} (needs purge permission, or purge protection is enabled)"
    fi
  done
fi

if [[ -n "$APP_ID" ]]; then
  read -rp "Also delete the app registration $APP_ID (tenant-level)? [y/N]: " A
  if [[ "$A" =~ ^[Yy]$ ]]; then
    if az ad app delete --id "$APP_ID"; then
      echo "${GRN}App registration deleted.${RST}"
    else
      echo "${RED}App registration deletion failed${RST} (check Entra permissions)."
    fi
  else
    echo "Left the app registration in place."
  fi
fi

echo "${GRN}Done.${RST}"
