# Filename: 1-Preflight.ps1
# Checks that this Windows machine is ready for the Credential Provider installation, then prints
# the values to enter in the installation wizard.
#
# Checks: the Provider is not installed yet, the Vault address is a host name (the installer
# crashes without a message on a URL or a typo), it resolves, the Vault port is reachable,
# the public IP for the Privilege Cloud allowlist, and disk space.
#
# Read-only: changes nothing. Run it on the CP machine before installing.
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

try {
    $cp = (Import-ProviderSettings -Path $ConfigPath -Required Cp).Cp
} catch {
    Write-Result fail $_.Exception.Message
    exit 1
}
$port = if ($cp.VaultPort) { [int]$cp.VaultPort } else { 1858 }

$service = Get-ProviderService
if ($service) {
    Write-Result exists "Provider already installed - service '$($service.DisplayName)' is $($service.Status). Next: 2-Onboard.ps1, then 4-Test-Server.ps1"
    exit 0
}

$failed = $false
function Write-Check([bool]$Ok, [string]$Message, [string]$Hint) {
    if ($Ok) { Write-Result ok $Message } else { Write-Result fail $Message -Hint $Hint; $script:failed = $true }
}

# --- Vault address and connectivity ------------------------------------------------
$validAddress = $cp.VaultAddress -match '^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$'
Write-Check $validAddress "Vault address '$($cp.VaultAddress)' is a host name" 'Host name only - no https://, no path, no port. Privilege Cloud: vault-<subdomain>.privilegecloud.cyberark.cloud'

if ($validAddress) {
    $resolves = $true
    try { [Net.Dns]::GetHostAddresses($cp.VaultAddress) | Out-Null } catch { $resolves = $false }
    Write-Check $resolves 'Vault address resolves' 'Check the address for typos, and DNS from this machine'

    if ($resolves) {
        Write-Check (Test-TcpPort $cp.VaultAddress $port) "Vault port $port is reachable" 'Check the firewall / security group from this machine to the Vault'
    }
}

# Privilege Cloud accepts the Vault protocol only from allowlisted public IPs - an open port is not enough
if ($cp.VaultAddress -like '*.privilegecloud.cyberark.cloud') {
    try {
        $publicIp = (Invoke-RestMethod https://checkip.amazonaws.com -TimeoutSec 5).Trim()
        Write-Result info "Public IP $publicIp - it must be in the Privilege Cloud IP allowlist"
    } catch {
        Write-Result info 'Public IP unknown - the IP this machine connects from must be in the Privilege Cloud IP allowlist'
    }
}

# --- Disk space -----------------------------------------------------------------
$freeGB = [math]::Round((Get-PSDrive ($env:SystemDrive.TrimEnd(':'))).Free / 1GB, 1)
Write-Check ($freeGB -ge 2) "Free disk space: $freeGB GB" 'At least 2 GB free is needed'

if ($failed) {
    Write-Result fail 'Fix the failed checks before installing'
    exit 1
}

# --- What to enter in the installation wizard ----------------------------------------
$installer = if ($cp.VaultAddress -like '*.privilegecloud.cyberark.cloud') { 'installeruser@cyberark.cloud.<tenant-id>' } else { 'a Vault admin user' }
Write-Host ''
Write-Host 'Ready. Run setup.exe from the package as administrator, and enter:' -ForegroundColor Cyan
Write-Host "  Vault address : $($cp.VaultAddress)"
Write-Host "  Port          : $port"
Write-Host "  Vault user    : $installer"
Write-Host "  Provider user : Prov_$env:COMPUTERNAME (the default - Custom installation lets you change it)"
Write-Host 'Restart the machine after the installation, put the Provider user in Providers in the settings file, then run 2-Onboard.ps1' -ForegroundColor Cyan
