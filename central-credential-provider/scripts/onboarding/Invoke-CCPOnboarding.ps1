# Filename: Invoke-CCPOnboarding.ps1
# Brings the Vault to the state described in the settings file (settings.psd1):
# Applications (AppIDs + authentication methods), Safes, Safe members and accounts.
#
# Idempotent: only adds what is missing. Never deletes anything and never overwrites
# existing passwords or permissions - gaps in existing members are reported as warnings.
# Works on Windows PowerShell 5.1 and PowerShell 7+, against PAM Self-Hosted or Privilege Cloud.
#
# Examples:
#   ./Invoke-CCPOnboarding.ps1                                       # Uses ../settings.psd1
#   ./Invoke-CCPOnboarding.ps1 -ConfigPath ../settings-customer.psd1

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../settings.psd1'),
    [pscredential]$Credential,    # Optional - otherwise asked once per PowerShell window
    [switch]$NewCredential        # Ask for the credential again
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/CCP-Common.ps1')

$appsPath = '/WebServices/PIMServices.svc/Applications'

# Config field -> Vault authentication type
$authTypes = [ordered]@{
    AllowedMachines = 'machineAddress'
    OSUsers         = 'osUser'
    Paths           = 'path'
    Hashes          = 'hash'
}

# Permissions the CCP needs on a Safe
$appIdPermissions    = @{ retrieveAccounts = $true; listAccounts = $true }
$providerPermissions = @{ retrieveAccounts = $true; listAccounts = $true; viewSafeMembers = $true }

# Full control for the human owners - a Safe created through the API is otherwise owned only by the API user
$ownerPermissions = @{
    useAccounts = $true; retrieveAccounts = $true; listAccounts = $true; addAccounts = $true
    updateAccountContent = $true; updateAccountProperties = $true; initiateCPMAccountManagementOperations = $true
    specifyNextAccountContent = $true; renameAccounts = $true; deleteAccounts = $true; unlockAccounts = $true
    manageSafe = $true; manageSafeMembers = $true; backupSafe = $true; viewAuditLog = $true; viewSafeMembers = $true
    accessWithoutConfirmation = $true; createFolders = $true; deleteFolders = $true; moveAccountsAndFolders = $true
}

function Add-SafeMemberIfMissing {
    param($Session, $SafeName, $Members, $MemberName, $Permissions, $MemberType = 'User')

    $member = $Members | Where-Object { $_.memberName -eq $MemberName }

    if (-not $member) {
        Invoke-CCPApi -Session $Session -Method Post -Path "/API/Safes/$([uri]::EscapeDataString($SafeName))/Members" -Body @{
            memberName  = $MemberName
            memberType  = $MemberType
            permissions = $Permissions
        } | Out-Null
        Write-Result added "  Member '$MemberName'"
        return
    }

    $missing = $Permissions.Keys | Where-Object { -not $member.permissions.$_ }
    if ($missing) {
        Write-Result warn "  Member '$MemberName' exists but is missing: $($missing -join ', ')"
    } else {
        Write-Result exists "  Member '$MemberName'"
    }
}

$platformStates = @{}    # PlatformId -> 'ok' / 'not found' / 'inactive', checked once per platform

function Get-PlatformState {
    param($Session, [string]$PlatformId)
    if (-not $platformStates.ContainsKey($PlatformId)) {
        $platform = Invoke-CCPApi -Session $Session -Method Get -Path "/API/Platforms/$([uri]::EscapeDataString($PlatformId))/" -AllowNotFound
        $platformStates[$PlatformId] = if (-not $platform) { 'not found' } elseif ($platform.Active -eq $false) { 'inactive' } else { 'ok' }
    }
    $platformStates[$PlatformId]
}

function New-CCPQuery {
    # Body for POST /AIMWebService/api/Accounts
    param($AppId, $SafeName, $ObjectName)
    [ordered]@{ AppID = $AppId; Safe = $SafeName; Object = $ObjectName } | ConvertTo-Json -Compress
}

function New-DemoPassword {
    # Random demo password; the fixed prefix satisfies typical platform complexity rules
    $chars = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    $bytes = New-Object byte[] 16
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    'Aa1!' + -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

$appsChanged = $false    # The Provider caches Applications - changes need a restart (or its cache refresh)
$queries = @()    # Ready-to-use CCP request bodies, built from the actual Object names in the Vault

try {
    $config = Import-CCPSettings -Path $ConfigPath -Required Connection, Applications, Safes -Optional SafeOwners
    $session = Connect-CCPVault -Connection $config.Connection -Credential $Credential -NewCredential:$NewCredential
} catch {
    Write-Host "[error]    $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (-not $config.SafeOwners) {
    Write-Result info 'No SafeOwners - new Safes are managed only by the logged-on user'
}

try {
    # --- Applications -------------------------------------------------------
    foreach ($app in $config.Applications) {
        $appIdEncoded = [uri]::EscapeDataString($app.AppId)

        $existing = (Invoke-CCPApi -Session $session -Method Get -Path "${appsPath}?AppID=$appIdEncoded").application |
            Where-Object { $_.AppID -eq $app.AppId }

        if ($existing) {
            Write-Result exists "Application '$($app.AppId)'"
        } else {
            $description = if ($app.Description) { $app.Description } else { 'Created by Invoke-CCPOnboarding' }
            Invoke-CCPApi -Session $session -Method Post -Path $appsPath -Body @{
                application = @{ AppID = $app.AppId; Description = $description; Location = '\Applications' }
            } | Out-Null
            Write-Result created "Application '$($app.AppId)'"
            $appsChanged = $true
        }

        $authPath = "$appsPath/$appIdEncoded/Authentications/"
        $current  = (Invoke-CCPApi -Session $session -Method Get -Path $authPath).authentication

        foreach ($field in $authTypes.Keys) {
            $type = $authTypes[$field]
            foreach ($value in $app[$field]) {
                if ($current | Where-Object { $_.AuthType -eq $type -and $_.AuthValue -eq $value }) {
                    Write-Result exists "  $type $value"
                } else {
                    Invoke-CCPApi -Session $session -Method Post -Path $authPath -Body @{
                        authentication = @{ AuthType = $type; AuthValue = $value }
                    } | Out-Null
                    Write-Result added "  $type $value"
                    $appsChanged = $true
                }
            }
        }

        if (-not ($authTypes.Keys | Where-Object { $app[$_] })) {
            Write-Result warn "  No authentication methods configured - any machine can retrieve with this AppID"
        }
    }

    # --- Safes, members and accounts ---------------------------------------
    foreach ($safe in $config.Safes) {
        $safeEncoded = [uri]::EscapeDataString($safe.Name)

        if (Invoke-CCPApi -Session $session -Method Get -Path "/API/Safes/$safeEncoded" -AllowNotFound) {
            Write-Result exists "Safe '$($safe.Name)'"
        } else {
            Invoke-CCPApi -Session $session -Method Post -Path '/API/Safes' -Body @{
                safeName    = $safe.Name
                description = 'Created by Invoke-CCPOnboarding'
                managingCPM = ''    # No CPM - demo passwords are not rotated against real targets
            } | Out-Null
            Write-Result created "Safe '$($safe.Name)'"
        }

        $members = (Invoke-CCPApi -Session $session -Method Get -Path "/API/Safes/$safeEncoded/Members?limit=1000").value

        foreach ($owner in $config.SafeOwners) {
            $ownerType = if ($owner.Type) { $owner.Type } else { 'User' }
            Add-SafeMemberIfMissing $session $safe.Name $members $owner.Name $ownerPermissions $ownerType
        }

        foreach ($appId in $safe.AppIds) {
            Add-SafeMemberIfMissing $session $safe.Name $members $appId $appIdPermissions
        }

        if (-not $safe.Providers) {
            $available = (Invoke-CCPApi -Session $session -Method Get -Path '/API/Users?componentUser=true&userType=AppProvider').Users.username
            Write-Result warn "  No Providers configured for this Safe. Available: $($available -join ', ')"
        }
        foreach ($provider in $safe.Providers) {
            $found = (Invoke-CCPApi -Session $session -Method Get -Path "/API/Users?search=$([uri]::EscapeDataString($provider))").Users |
                Where-Object { $_.username -eq $provider }
            if (-not $found) {
                Write-Result warn "  Provider '$provider' not found in the Vault - skipped (install the Provider and re-run)"
                continue
            }
            Add-SafeMemberIfMissing $session $safe.Name $members $provider $providerPermissions
        }

        $filter   = [uri]::EscapeDataString("safeName eq $($safe.Name)")
        $accounts = (Invoke-CCPApi -Session $session -Method Get -Path "/API/Accounts?filter=$filter&limit=1000").value

        foreach ($account in $safe.Accounts) {
            $label = "$($account.UserName)@$($account.Address)"

            # Accounts are matched by user + address: the Object name is usually generated by the
            # platform naming convention (always, when created manually in the PVWA), so it is read back.
            $existing = $accounts |
                Where-Object { $_.userName -eq $account.UserName -and $_.address -eq $account.Address } |
                Select-Object -First 1

            if ($existing) {
                Write-Result exists "  Account $label (Object: $($existing.name))"
                $objectName = $existing.name
            } else {
                $platformState = Get-PlatformState $session $account.PlatformId
                if ($platformState -ne 'ok') {
                    Write-Result warn "  Account $label skipped - platform '$($account.PlatformId)' is $platformState" `
                        -Hint 'Activate the platform in the PVWA (Platform Management), or use another PlatformId'
                    continue
                }

                $body = @{
                    safeName   = $safe.Name
                    platformId = $account.PlatformId
                    address    = $account.Address
                    userName   = $account.UserName
                    secretType = 'password'
                    secret     = if ($account.Secret) { $account.Secret } else { New-DemoPassword }
                }
                if ($account.Name) { $body.name = $account.Name }

                $created = Invoke-CCPApi -Session $session -Method Post -Path '/API/Accounts' -Body $body
                Write-Result created "  Account $label (Object: $($created.name))$(if (-not $account.Secret) { ' - random password' })"
                $objectName = $created.name
            }

            $queries += foreach ($appId in $safe.AppIds) { New-CCPQuery $appId $safe.Name $objectName }
        }
    }

    # --- Ready-to-use CCP requests -----------------------------------------
    Write-Host ''
    if ($appsChanged) {
        Write-Result warn 'Applications changed - the Provider caches them, so restart the Provider service on each CCP server to apply the change now'
    }
    if ($queries) { Write-Result info 'CCP request - POST /AIMWebService/api/Accounts with body:' }
    foreach ($query in $queries) { Write-Result info $query }
} catch {
    Write-Host "[error]    $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Disconnect-CCPVault -Session $session
}
