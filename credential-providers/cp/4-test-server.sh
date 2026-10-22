#!/usr/bin/env bash
# Filename: 4-test-server.sh
# Checks the machine side of the Credential Provider on Linux: the Provider service, connectivity
# to the Vault from vault.ini, recent errors in the Provider logs, and a test retrieval through
# clipasswordsdk with the Provider error code explained.
#
# Read-only: changes nothing. The test retrieval asks for the account's user name - never the password.
# Run it on the CP machine, as root (the Provider logs are readable by root only).
# For the Vault side use 3-Test-Vault.ps1.
#
# Usage:
#   ./4-test-server.sh                   # Uses settings.conf next to the script
#   ./4-test-server.sh settings-customer.conf

set -u

config="${1:-$(dirname "$0")/settings.conf}"

# CP paths on Linux (The UNIX environment on the Credential Provider machine, CP docs)
vault_ini=/etc/opt/CARKaim/vault/vault.ini
logs=/var/opt/CARKaim/logs
sdk=/opt/CARKaim/sdk

setting() {    # setting <KEY> - its value in the settings file (KEY=VALUE, no quotes); read as data, never executed
    sed -n "s/^$1=//p" "$config" | tail -n 1 | tr -d '\r'
}

if [ -t 1 ]; then
    red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; cyan=$'\e[36m'; gray=$'\e[90m'; reset=$'\e[0m'
else
    red=''; green=''; yellow=''; cyan=''; gray=''; reset=''
fi

result() {    # result <status> <message> [hint] - same format as the PowerShell scripts
    local color
    case "$1" in
        ok)   color=$green ;;
        fail) color=$red ;;
        warn) color=$yellow ;;
        skip) color=$gray ;;
        *)    color=$cyan ;;
    esac
    printf '%s%-10s %s%s\n' "$color" "[$1]" "$2" "$reset"
    if [ -n "${3:-}" ]; then printf '%s%-10s -> %s%s\n' "$color" '' "$3" "$reset"; fi
}

error_hint() {    # error_hint <code> - what to check for a Provider error code
    case "$1" in
        APPAP22[7-9]E|APPAP230E) echo 'More than one account matches - narrow the query with UserName and Address' ;;
        APPAP007E|APPBC007E)     echo 'The Provider cannot reach the Vault - check the Provider service and the network to the Vault' ;;
        APPAP306E)               echo 'Application authentication failed - check the AppID Allowed Machines / OS user / path / hash. APPAudit.log (APPAP133E) shows the value that was rejected. Already fixed in the Vault? Restart the Provider - it caches Applications' ;;
        APPAP004E)               echo 'Object not found, or the AppID / Provider user has no permission on it - run 3-Test-Vault.ps1 for this AppID and Safe' ;;
        APPAP093E|APPAP127E)     echo 'The Provider user is missing the Audit Users authorization, or its user type is not AppProvider' ;;
        APPAP282E)               echo 'The CPM is changing this password right now - retry in a moment' ;;
        *)                       echo 'Look up the error code in the CyberArk Credential Providers documentation' ;;
    esac
}

echo "${cyan}Read-only: this script changes nothing and never displays passwords${reset}"
echo

# --- Provider service --------------------------------------------------------------
if [ ! -e /etc/init.d/aimprv ]; then
    result fail 'Provider not installed - /etc/init.d/aimprv not found' 'Install the CP - run 1-preflight.sh for the steps'
    exit 1
fi
if /etc/init.d/aimprv status >/dev/null 2>&1; then
    result ok 'Provider service (aimprv) is running'
else
    result fail 'Provider service (aimprv) is not running' 'Start it with /etc/init.d/aimprv start and check APPConsole.log for the reason it stopped'
fi

# --- Vault connectivity, from the vault.ini the Provider uses --------------------------
if [ -r "$vault_ini" ]; then
    addresses=$(sed -n 's/^[[:space:]]*ADDRESS[[:space:]]*=[[:space:]]*//p' "$vault_ini" | tr -d '\r' | tr ',' ' ')
    port=$(sed -n 's/^[[:space:]]*PORT[[:space:]]*=[[:space:]]*//p' "$vault_ini" | tr -d '\r'); port=${port:-1858}
    for vault in $addresses; do
        if timeout 3 bash -c "</dev/tcp/$vault/$port" 2>/dev/null; then
            result ok "Vault $vault:$port is reachable"
        else
            result fail "Vault $vault:$port is not reachable" 'Check the firewall / security group from this machine to the Vault'
        fi
    done
else
    result skip "Vault connectivity - $vault_ini not readable (run as root)"
fi

# --- Provider logs ---------------------------------------------------------------
# APPConsole.log has service errors; APPAudit.log has the reason each request failed (e.g. APPAP133E)
for name in APPConsole.log APPAudit.log; do
    log="$logs/$name"
    if [ ! -r "$log" ]; then
        result skip "$name - not readable under $logs (run as root)"
        continue
    fi
    errors=$(tail -n 300 "$log" | grep -E '\b[A-Z]{3,6}[0-9]{3}E\b')
    if [ -z "$errors" ]; then
        result ok "$name - no errors in the last 300 lines"
    else
        result warn "$name - $(echo "$errors" | wc -l) error lines in the last 300 lines. Latest:"
        echo "$errors" | tail -n 3 | sed 's/^/             /'
    fi
done

# --- Test retrieval ----------------------------------------------------------------
if [ ! -f "$config" ]; then
    result skip "Test retrieval - no settings file ($config)"
    exit 0
fi
app_id=$(setting APP_ID); safe=$(setting SAFE); username=$(setting USERNAME); address=$(setting ADDRESS)
if [ -z "$app_id" ] || [ -z "$safe" ] || { [ -z "$username" ] && [ -z "$address" ]; }; then
    result skip "Test retrieval - set APP_ID, SAFE and USERNAME / ADDRESS in $config"
    exit 0
fi

cli=$(find "$sdk" -maxdepth 1 -iname clipasswordsdk -type f 2>/dev/null | head -n 1)
if [ -z "$cli" ]; then
    result skip "Test retrieval - clipasswordsdk not found in $sdk"
    exit 0
fi

query="Safe=$safe;Folder=Root"
[ -n "$username" ] && query="$query;UserName=$username"
[ -n "$address" ] && query="$query;Address=$address"
result info "Test retrieval: AppID $app_id, Query $query"

# PassProps.UserName returns the account's user name - proves the retrieval without the password
if output=$("$cli" GetPassword -p "AppDescs.AppID=$app_id" -p "Query=$query" -p 'Reason=CP health check' -o PassProps.UserName 2>&1); then
    result ok "Retrieved account '$output' - password not requested"
else
    code=$(echo "$output" | grep -oE '\b[A-Z]{3,6}[0-9]{3}E\b' | head -n 1)
    result fail "$output" "$(error_hint "$code")"
    reason=$(tail -n 20 "$logs/APPAudit.log" 2>/dev/null | grep -E '\b[A-Z]{3,6}[0-9]{3}E\b' | tail -n 1)
    [ -n "$reason" ] && result info "APPAudit.log: $reason"
    if [ "$code" = 'APPAP306E' ]; then
        result info "Note: this test runs as $cli under $(id -un) - an AppID that also checks Path, Hash or OS user accepts only the real application"
    fi
fi
