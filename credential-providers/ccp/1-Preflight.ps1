# Filename: 1-Preflight.ps1
# Checks that this Windows server is ready for the CCP installation, then prints the values to enter
# in the Credential Provider installation wizard. The IIS features the CCP needs can be installed
# with lab/Install-IISPrerequisites.ps1.
#
# Checks: the Provider is not installed yet, the Vault address is a host name (the installer
# crashes without a message on a URL or a typo), it resolves, the Vault port is reachable,
# the public IP for the Privilege Cloud allowlist, and disk space.
# The Vault address comes from Vault.Address, or for Privilege Cloud from Connection.PvwaUrl.
#
# Read-only: changes nothing. Run it on the CCP server before installing.
#
# Examples:
#   ./1-Preflight.ps1
#   ./1-Preflight.ps1 -ConfigPath ./settings-customer.psd1

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'settings.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/Provider-Common.ps1')
. (Join-Path $PSScriptRoot '../common/ProviderHost.ps1')
. (Join-Path $PSScriptRoot '../common/Preflight.ps1')

try {
    $vault = Resolve-Vault -Settings (Import-ProviderSettings -Path $ConfigPath)
} catch {
    Write-Result fail $_.Exception.Message
    exit 1
}

switch (Invoke-Preflight -Vault $vault) {
    'installed' { Write-Result info 'Next: 2-Onboard.ps1, then 4-Test-Server.ps1'; exit 0 }
    'failed'    { exit 1 }
}

Write-NextSteps -Vault $vault -Product CCP
