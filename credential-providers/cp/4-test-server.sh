#!/usr/bin/env bash
# Filename: 4-test-server.sh
# Checks the machine side of the Credential Provider on Linux: the Provider service, connectivity
# to the Vault from vault.ini, recent errors in the Provider logs, whether applications can run the
# SDK, and a test retrieval through clipasswordsdk - as the application's OS user, not root - with
# the Provider error code explained.
#
# Read-only: changes nothing. The test retrieval asks for the account's user name - never the password.
# Run it on the CP machine with sudo (the Provider logs and vault.ini are readable by root only).
# For the Vault side use 3-Test-Vault.ps1.
#
# Usage - 2-Onboard.ps1 prints the command with the AppID and account:
#   sudo ./4-test-server.sh                                        # Machine checks only
#   sudo ./4-test-server.sh <AppID> <Safe> <UserName> [Address]    # And a test retrieval
# The optional settings.conf next to the script sets APP_OS_USER.

set -u

config="$(dirname "$0")/settings.conf"
app_id="${1:-}"; safe="${2:-}"; username="${3:-}"; address="${4:-}"

# CP paths on Linux (The UNIX environment on the Credential Provider machine, CP docs)
vault_ini=/etc/opt/CARKaim/vault/vault.ini
logs=/var/opt/CARKaim/logs
sdk=/opt/CARKaim/sdk

setting() {    # setting <KEY> - its value in the settings file (KEY=VALUE, no quotes); read as data, never executed
    [ -f "$config" ] && sed -n "s/^$1=//p" "$config" | tail -n 1 | tr -d '\r'
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
        APPAP133E|APPAP306E)     echo "The AppID authentication failed - the APPAudit.log line below shows the values this machine sent. Add its private IP (Allowed Machines), OS user or path to the AppID, then restart the Provider - it caches Applications: sudo /etc/init.d/aimprv restart" ;;
        APPAP425E)               echo 'The AppID does not exist in the Vault - check APP_ID in the settings file against 3-Test-Vault.ps1' ;;
        APPAP004E)               echo 'Object not found, or the AppID / Provider user has no permission on it - run 3-Test-Vault.ps1 for this AppID and Safe. Just added the Provider to the Safe? Restart it - it caches Safe permissions: sudo /etc/init.d/aimprv restart' ;;
        APPAP093E|APPAP127E)     echo 'The Provider user is missing the Audit Users authorization, or its user type is not AppProvider' ;;
        APPAP282E)               echo 'The CPM is changing this password right now - retry in a moment' ;;
        *)                       echo 'Look up the error code in the CyberArk Credential Providers documentation' ;;
    esac
}

echo "${cyan}Read-only: this script changes nothing and never displays passwords${reset}"
echo

if [ "$(id -u)" -ne 0 ]; then
    result fail 'Not running as root - the Provider service, vault.ini and logs are root-only' 'Run: sudo ./4-test-server.sh'
    exit 1
fi

# --- Provider service --------------------------------------------------------------
if [ ! -e /etc/init.d/aimprv ]; then
    result fail 'Provider not installed - /etc/init.d/aimprv not found' 'Install the CP - run 1-preflight.sh for the steps'
    exit 1
fi
if /etc/init.d/aimprv status >/dev/null 2>&1; then
    result ok 'Provider service (aimprv) is running'
else
    result fail 'Provider service (aimprv) is not running' 'Start it: sudo /etc/init.d/aimprv start - if it stops again, APPConsole.log has the reason'
fi

# --- Registered in the Vault? ----------------------------------------------------
# The installer reports success even when it could not create the Provider in the Vault
if [ -f /etc/opt/CARKaim/vault/appprovideruser.cred ]; then
    result ok 'Provider registered in the Vault (appprovideruser.cred)'
else
    result fail 'Provider not registered in the Vault - /etc/opt/CARKaim/vault/appprovideruser.cred is missing' \
        'Register it with createenv - 1-preflight.sh prints the command. Its log: /var/tmp/aim-install-logs/CreateEnv.log'
fi

# --- Vault connectivity, from the vault.ini the Provider uses --------------------------
if [ -r "$vault_ini" ]; then
    addresses=$(sed -n 's/^[[:space:]]*ADDRESS[[:space:]]*=[[:space:]]*//p' "$vault_ini" | tr -d '\r' | tr ',' ' ')
    port=$(sed -n 's/^[[:space:]]*PORT[[:space:]]*=[[:space:]]*//p' "$vault_ini" | tr -d '[:space:]'); port=${port:-1858}
    for vault in $addresses; do
        if timeout 3 bash -c "</dev/tcp/$vault/$port" 2>/dev/null; then
            result ok "Vault $vault:$port is reachable"
        else
            result fail "Vault $vault:$port is not reachable" 'Check the firewall / security group from this machine to the Vault'
        fi
    done
else
    result skip "Vault connectivity - $vault_ini not found"
fi

# --- Provider logs ---------------------------------------------------------------
# APPConsole.log has service errors; APPAudit.log has the reason each request failed (e.g. APPAP133E)
for name in APPConsole.log APPAudit.log; do
    log="$logs/$name"
    if [ ! -r "$log" ]; then
        result skip "$name - not found under $logs"
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

# --- Can applications run the SDK? ------------------------------------------------
# HardenFSPermissions=yes (the installer default) removes the "other" permissions - then only root can run it
sdk_mode=$(stat -c %a "$sdk" 2>/dev/null)
if [ -z "$sdk_mode" ]; then
    result fail "SDK folder $sdk not found" 'Check the CP installation'
elif [ $((${sdk_mode: -1} & 1)) -eq 1 ]; then
    result ok "SDK folder $sdk is open to applications ($sdk_mode)"
else
    result warn "SDK folder $sdk is $sdk_mode ($(stat -c %U:%G "$sdk")) - applications not running as root cannot use the SDK" \
        'Installed with HardenFSPermissions=yes - reinstall with HardenFSPermissions=no in /var/tmp/aimparms'
fi

# --- Test retrieval ----------------------------------------------------------------
if [ -z "$app_id" ]; then
    result skip 'Test retrieval - pass the AppID, Safe and account; 2-Onboard.ps1 prints the command'
    exit 0
fi
if [ -z "$safe" ] || { [ -z "$username" ] && [ -z "$address" ]; }; then
    result fail 'Test retrieval - pass <AppID> <Safe> <UserName> [Address]'
    exit 1
fi

cli=$(find "$sdk" -maxdepth 1 -iname clipasswordsdk -type f 2>/dev/null | head -n 1)
if [ -z "$cli" ]; then
    result skip "Test retrieval - clipasswordsdk not found in $sdk"
    exit 0
fi

# As the application would run it - not as root. Default: the user who ran sudo.
run_as=$(setting APP_OS_USER); run_as=${run_as:-${SUDO_USER:-root}}
if ! id "$run_as" >/dev/null 2>&1; then
    result fail "Test retrieval - OS user '$run_as' does not exist" 'Set APP_OS_USER in settings.conf to the OS user the application runs as'
    exit 1
fi

query="Safe=$safe;Folder=Root"
[ -n "$username" ] && query="$query;UserName=$username"
[ -n "$address" ] && query="$query;Address=$address"
result info "Test retrieval as $run_as: AppID $app_id, Query $query"

# PassProps.UserName returns the account's user name - proves the retrieval without the password
if output=$(sudo -u "$run_as" "$cli" GetPassword -p "AppDescs.AppID=$app_id" -p "Query=$query" -p 'Reason=CP health check' -o PassProps.UserName 2>&1); then
    result ok "Retrieved account '$output' - password not requested"
else
    code=$(echo "$output" | grep -oE '\b[A-Z]{3,6}[0-9]{3}E\b' | head -n 1)
    reason=$(tail -n 20 "$logs/APPAudit.log" 2>/dev/null | grep -E '\b[A-Z]{3,6}[0-9]{3}E\b' | tail -n 1)
    # APPEX003E is generic - the specific code is the last one in the APPAudit.log line
    if [ "$code" = 'APPEX003E' ] && [ -n "$reason" ]; then
        code=$(echo "$reason" | grep -oE '\b[A-Z]{3,6}[0-9]{3}E\b' | tail -n 1)
    fi
    if echo "$output" | grep -qi 'permission denied'; then
        result fail "$output" "OS user $run_as cannot run the SDK - see the SDK folder check above"
    else
        result fail "$output" "$(error_hint "$code")"
    fi
    [ -n "$reason" ] && result info "APPAudit.log: $reason"
    if [ "$code" = 'APPAP133E' ] || [ "$code" = 'APPAP306E' ]; then
        result info "Note: this test runs $cli as $run_as - an AppID that also checks Path, Hash or OS user accepts only the real application"
    fi
fi
