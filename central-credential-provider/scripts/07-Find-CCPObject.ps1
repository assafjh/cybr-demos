# Filename: 07-Find-CCPObject.ps1
# Finds accounts in the Vault (via PVWA, using the community psPAS module) and shows
# the exact Object name and parameters to use in a CCP request.
# Optionally checks that the AppID and the CCP Provider user are members of the Safe.
# Supports PAM Self-Hosted (default) and Privilege Cloud (-TenantSubdomain).
# Works on Windows PowerShell 5.1 and PowerShell 7+.

param(
    # PAM Self-Hosted: PVWA base URL (without /PasswordVault)
    [string]$PvwaUrl = "https://<pvwa-host>",

    # PAM Self-Hosted: CyberArk / LDAP / RADIUS / Windows
    [ValidateSet("CyberArk", "LDAP", "RADIUS", "Windows")]
    [string]$AuthType = "CyberArk",

    # Privilege Cloud: tenant subdomain (e.g. "mycompany"). When set, PvwaUrl/AuthType are ignored
    [string]$TenantSubdomain = "",

    # Safe to search in
    [string]$Safe = "Credential-Providers",

    # Keywords (username, address, part of the name). Empty = all accounts in the Safe
    [string]$Search = "",

    # AppID the CCP request will use. Empty = skip the membership check
    [string]$AppID = "AIMWebService",

    # CCP Provider user, e.g. "Prov_CCPHOST". Empty = skip the membership check
    [string]$ProviderUser = ""
)

# Ensure psPAS is installed and loaded
if (-not (Get-Module -ListAvailable -Name psPAS)) {
    Write-Host "psPAS module not found - installing for the current user..." -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-Module -Name psPAS -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
        Write-Host "Failed to install psPAS:" $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}
Import-Module psPAS -ErrorAction Stop

# Connect
try {
    if ($TenantSubdomain) {
        # Privilege Cloud - requires an Identity service user (OAuth)
        $cred = Get-Credential -Message "Identity service user for Privilege Cloud"
        New-PASSession -TenantSubdomain $TenantSubdomain -Credential $cred -ErrorAction Stop
    } elseif ($AuthType -eq "Windows") {
        New-PASSession -BaseURI $PvwaUrl -UseDefaultCredentials -ErrorAction Stop
    } else {
        $cred = Get-Credential -Message "Vault user with List permission on the Safe"
        New-PASSession -BaseURI $PvwaUrl -Credential $cred -type $AuthType -ErrorAction Stop
    }
} catch {
    Write-Host "Logon failed:" $_.Exception.Message -ForegroundColor Red
    exit 1
}

try {
    # Find accounts
    $searchParams = @{ safeName = $Safe; ErrorAction = 'Stop' }
    if ($Search) { $searchParams.search = $Search }
    $accounts = @(Get-PASAccount @searchParams)

    if ($accounts.Count -eq 0) {
        Write-Host "No accounts found in Safe '$Safe'" -ForegroundColor Red
        Write-Host "Check the Safe name and that the logged-on user has List permission on it." -ForegroundColor Red
    } else {
        Write-Host "`nFound $($accounts.Count) account(s) in Safe '$Safe':`n" -ForegroundColor Green
        $accounts | Select-Object @{n='Object (use in CCP)';e={$_.name}}, userName, address, platformId |
            Format-Table -AutoSize

        foreach ($a in $accounts) {
            $q = "AppID=$([uri]::EscapeDataString($AppID))&Safe=$([uri]::EscapeDataString($Safe))&Object=$([uri]::EscapeDataString($a.name))"
            Write-Host "CCP query for '$($a.name)':" -ForegroundColor Cyan
            Write-Host " /AIMWebService/api/Accounts?$q"
        }

        # Warn about duplicate names (CCP will fail on ambiguous matches)
        $accounts | Group-Object name | Where-Object Count -gt 1 | ForEach-Object {
            Write-Host "WARNING: Object name '$($_.Name)' appears $($_.Count) times in the Safe" -ForegroundColor Yellow
        }
    }

    # Check Safe membership for the AppID and the Provider user
    $members = $null
    if ($AppID -or $ProviderUser) {
        try {
            $members = @(Get-PASSafeMember -SafeName $Safe -ErrorAction Stop)
        } catch {
            Write-Host "`nCould not read Safe members (needs View Safe Members permission):" $_.Exception.Message -ForegroundColor Yellow
        }
    }
    if ($members) {
        Write-Host "`nSafe membership checks:" -ForegroundColor Cyan
        foreach ($m in @($AppID, $ProviderUser) | Where-Object { $_ }) {
            $member = $members | Where-Object { $_.memberName -eq $m }
            if (-not $member) {
                Write-Host " [X] '$m' is NOT a member of Safe '$Safe'" -ForegroundColor Red
            } else {
                $p = $member.permissions
                $ok = $p.retrieveAccounts -and $p.listAccounts
                $color = if ($ok) { 'Green' } else { 'Red' }
                Write-Host " [$(if ($ok) {'V'} else {'X'})] '$m' - Retrieve: $($p.retrieveAccounts), List: $($p.listAccounts)" -ForegroundColor $color
            }
        }
    }
} catch {
    Write-Host "Request failed:" $_.Exception.Message -ForegroundColor Red
} finally {
    Close-PASSession -ErrorAction SilentlyContinue
}
