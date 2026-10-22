# Filename: Preflight.ps1
# Shared by the CP and CCP preflights (1-Preflight.ps1) - dot-source it after Provider-Common.ps1
# and ProviderHost.ps1, then call Invoke-Preflight on the machine the Provider will be installed on.

function Resolve-Vault {
    # The Vault the Provider connects to: Vault.Address from the settings file, or for Privilege Cloud
    # derived from Connection.PvwaUrl (https://<subdomain>.privilegecloud.cyberark.cloud -> vault-<subdomain>...)
    param([Parameter(Mandatory)] [hashtable]$Settings)

    $port = if ($Settings.Vault.Port) { [int]$Settings.Vault.Port } else { 1858 }

    if ($Settings.Vault.Address -and $Settings.Vault.Address -notmatch '<[^<>]+>') {
        return @{ Address = $Settings.Vault.Address; Port = $port; Source = 'Vault.Address' }
    }
    $pvwaHost = if ($Settings.Connection.PvwaUrl -match '^https://([^/]+)') { $Matches[1] }
    if ($pvwaHost -like '*.privilegecloud.cyberark.cloud' -and $pvwaHost -notmatch '[<>]') {
        return @{ Address = "vault-$pvwaHost"; Port = $port; Source = 'Connection.PvwaUrl' }
    }
    throw 'Set Vault.Address in the settings file - it is derived only from a Privilege Cloud PvwaUrl (https://<subdomain>.privilegecloud.cyberark.cloud)'
}

function Invoke-Preflight {
    # Checks the Vault address, DNS, the Vault port (for Privilege Cloud: the IP allowlist) and
    # disk space. Returns 'installed' when the Provider is already here, 'failed' or 'ready'.
    param([Parameter(Mandatory)] [hashtable]$Vault)

    $service = Get-ProviderService
    if ($service) {
        Write-Result exists "Provider already installed - service '$($service.DisplayName)' is $($service.Status)"
        return 'installed'
    }

    $checks = @{ Failed = $false }    # Set by Write-Check
    function Write-Check([bool]$Ok, [string]$Message, [string]$Hint) {
        if ($Ok) { Write-Result ok $Message } else { Write-Result fail $Message -Hint $Hint; $checks.Failed = $true }
    }

    Write-Result info "Vault $($Vault.Address):$($Vault.Port) (from $($Vault.Source))"

    # The installer crashes without a message on a URL or a typo here, so check it first
    $validAddress = $Vault.Address -match '^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$'
    Write-Check $validAddress 'Vault address is a host name' 'Host name only - no https://, no path, no port. Privilege Cloud: vault-<subdomain>.privilegecloud.cyberark.cloud'

    if ($validAddress) {
        $resolves = $true
        try { [Net.Dns]::GetHostAddresses($Vault.Address) | Out-Null } catch { $resolves = $false }
        Write-Check $resolves 'Vault address resolves' 'Check the address for typos, and DNS from this machine'

        if ($resolves) {
            $reachable = Test-TcpPort $Vault.Address $Vault.Port
            $hint = 'Check the firewall / security group from this machine to the Vault'
            if (-not $reachable -and $Vault.Address -like '*.privilegecloud.cyberark.cloud') {
                # Privilege Cloud refuses connections from public IPs that are not in its allowlist
                $publicIp = 'unknown'
                try { $publicIp = (Invoke-RestMethod https://checkip.amazonaws.com -TimeoutSec 5).Trim() } catch { }
                $hint = "Add this machine's public IP ($publicIp) to the Privilege Cloud IP allowlist, and check the firewall / security group"
            }
            Write-Check $reachable "Vault port $($Vault.Port) is reachable" $hint
        }
    }

    $freeGB = [math]::Round((Get-PSDrive ($env:SystemDrive.TrimEnd(':'))).Free / 1GB, 1)
    Write-Check ($freeGB -ge 2) "Free disk space: $freeGB GB" 'At least 2 GB free is needed'

    if ($checks.Failed) {
        Write-Result fail 'Fix the failed checks before installing'
        return 'failed'
    }
    'ready'
}

function Write-InstallValues {
    # What to enter in the installation wizard
    param([Parameter(Mandatory)] [hashtable]$Vault)
    $installer = if ($Vault.Address -like '*.privilegecloud.cyberark.cloud') { 'installeruser@cyberark.cloud.<tenant-id>' } else { 'a Vault admin user' }
    Write-Host "  Vault address : $($Vault.Address)"
    Write-Host "  Port          : $($Vault.Port)"
    Write-Host "  Vault user    : $installer"
    Write-Host "  Provider user : Prov_$env:COMPUTERNAME (the default - Custom installation lets you change it)"
}
