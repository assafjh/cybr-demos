#!/usr/bin/env bash
# Filename: 1-preflight.sh
# Checks that this Linux machine is ready for the Credential Provider installation, then prints
# the values for Vault.ini and /var/tmp/aimparms and the install commands.
#
# Checks: the Provider is not installed yet, a package manager the CP ships for (RPM or DEB),
# the Vault address is a host name, it resolves, the Vault port is reachable (for Privilege Cloud
# this also means the public IP is in the allowlist), and disk space.
#
# Read-only: changes nothing. Needs only bash - copy it with settings.conf to the CP machine.
#
# Usage:
#   ./1-preflight.sh                   # Uses settings.conf next to the script
#   ./1-preflight.sh settings-customer.conf

set -u

config="${1:-$(dirname "$0")/settings.conf}"

setting() {    # setting <KEY> - its value in the settings file (KEY=VALUE, no quotes); read as data, never executed
    sed -n "s/^$1=//p" "$config" | tail -n 1 | tr -d '\r'
}

if [ ! -f "$config" ]; then
    echo "Settings file not found: $config - copy settings.example.conf to settings.conf and fill it in"
    exit 1
fi
vault=$(setting VAULT_ADDRESS)
port=$(setting VAULT_PORT); port=${port:-1858}
if [ -z "$vault" ] || [[ "$vault" == *'<'* ]]; then
    echo "Fill in VAULT_ADDRESS in $config"
    exit 1
fi
failed=0

# Colors only on a terminal, so a saved log has no escape codes
if [ -t 1 ]; then
    red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; cyan=$'\e[36m'; gray=$'\e[90m'; reset=$'\e[0m'
else
    red=''; green=''; yellow=''; cyan=''; gray=''; reset=''
fi

result() {    # result <status> <message> [hint] - same format as the PowerShell scripts
    local color
    case "$1" in
        ok)     color=$green ;;
        fail)   color=$red; failed=1 ;;
        warn)   color=$yellow ;;
        exists) color=$gray ;;
        *)      color=$cyan ;;
    esac
    printf '%s%-10s %s%s\n' "$color" "[$1]" "$2" "$reset"
    if [ -n "${3:-}" ]; then printf '%s%-10s -> %s%s\n' "$color" '' "$3" "$reset"; fi
}

# --- Package format, and whether the CP is already installed --------------------
# The CP ships as RPM (RHEL, CentOS, Oracle Linux) and DEB (Ubuntu). Installed = the package is
# registered - folders such as /opt/CARKaim can stay behind after an uninstall.
if command -v rpm >/dev/null 2>&1 && ! command -v dpkg >/dev/null 2>&1; then
    package='rpm'
    installed=$(rpm -qa | grep -i '^carkaim')
elif command -v dpkg >/dev/null 2>&1; then
    package='deb'
    installed=$(dpkg-query -W 2>/dev/null | grep -i '^carkaim')
else
    package=''; installed=''
fi

if [ -n "$installed" ]; then
    result exists "Provider already installed ($installed) - check it with: /etc/init.d/aimprv status"
    exit 0
fi

case "$package" in
    rpm) result ok 'RPM-based distribution - install CARKaim-<version>.x86_64.rpm' ;;
    deb) result ok 'DEB-based distribution - install CARKaim-<version>.amd64.deb' ;;
    *) result fail 'Neither rpm nor dpkg found' 'The CP ships as RPM (RHEL, CentOS, Oracle Linux) and DEB (Ubuntu)' ;;
esac

# --- Vault address and connectivity ------------------------------------------------
# The installation fails on a URL or a typo here, so check it first
if [[ "$vault" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
    result ok "Vault address '$vault' is a host name"

    if getent hosts "$vault" >/dev/null 2>&1; then
        result ok 'Vault address resolves'
        if timeout 3 bash -c "</dev/tcp/$vault/$port" 2>/dev/null; then
            result ok "Vault port $port is reachable"
        elif [[ "$vault" == *.privilegecloud.cyberark.cloud ]]; then
            # Privilege Cloud refuses connections from public IPs that are not in its allowlist
            public_ip=$(curl -s --max-time 5 https://checkip.amazonaws.com 2>/dev/null || wget -qO- --timeout=5 https://checkip.amazonaws.com 2>/dev/null)
            result fail "Vault port $port is not reachable" "Add this machine's public IP (${public_ip:-unknown}) to the Privilege Cloud IP allowlist, and check the firewall / security group"
        else
            result fail "Vault port $port is not reachable" 'Check the firewall / security group from this machine to the Vault'
        fi
    else
        result fail 'Vault address does not resolve' 'Check the address for typos, and DNS from this machine'
    fi
else
    result fail "Vault address '$vault' is not a host name" 'Host name only - no https://, no path, no port. Privilege Cloud: vault-<subdomain>.privilegecloud.cyberark.cloud'
fi

privilege_cloud=0
[[ "$vault" == *.privilegecloud.cyberark.cloud ]] && privilege_cloud=1

# --- Disk space -----------------------------------------------------------------
# The CP installs under /opt, /var/opt and /etc/opt
for dir in /opt /var; do
    free_mb=$(df -Pm "$dir" | awk 'NR==2 {print $4}')
    if [ "${free_mb:-0}" -ge 2048 ]; then
        result ok "Free disk space on $dir: $((free_mb / 1024)) GB"
    else
        result fail "Free disk space on $dir: ${free_mb:-0} MB" 'At least 2 GB free is needed'
    fi
done

if [ "$(id -u)" -ne 0 ]; then
    result warn 'Not running as root - the installation itself needs root (this check does not)'
fi

if [ "$failed" -ne 0 ]; then
    result fail 'Fix the failed checks before installing'
    exit 1
fi

# --- What to set, and the install commands ------------------------------------------
if [ "$privilege_cloud" -eq 1 ]; then environment='PrivilegeCloud'; installer='installeruser@cyberark.cloud.<tenant-id>'
else environment='PamSelfHosted'; installer='a Vault admin user'; fi
install_cmd='rpm -ivh CARKaim-*.x86_64.rpm'
if [ "$package" = 'deb' ]; then install_cmd='dpkg -i CARKaim-*.amd64.deb'; fi

cat <<EOF

${cyan}Ready. In the folder with the unpacked package, as root:${reset}

  1. Vault.ini            ADDRESS=$vault
                          PORT=$port
  2. Credential file      ./CreateCredFile user.cred     (Vault user: $installer)
  3. Installation file    mv aimparms.sample /var/tmp/aimparms, then set:
                            AcceptCyberArkEULA=Yes
                            CredFilePath=<package-folder>/user.cred
                            VaultFilePath=<package-folder>/Vault.ini
                            EnvironmentType=$environment
                          Provider user: Prov_$(hostname) by default - AppProviderUser to change it
  4. Install              $install_cmd
  5. Clean up and check   rm user.cred; /etc/init.d/aimprv status

${cyan}Then put the Provider user in Providers in the settings file and run 2-Onboard.ps1${reset}
EOF
