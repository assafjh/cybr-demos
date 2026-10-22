# Filename: Onboarding.ps1
# Shared by the CP and CCP onboarding scripts (2-Onboard.ps1) - dot-source it, then call Invoke-Onboarding.
# Brings the Vault to the state described in the settings file: Applications (AppIDs +
# authentication methods), Safes, Safe members and accounts.
#
# Idempotent: only adds what is missing. Never deletes anything and never overwrites
# existing passwords or permissions - gaps in existing members are reported as warnings.

$appsPath = '/WebServices/PIMServices.svc/Applications'

# Config field -> Vault authentication type
$authTypes = [ordered]@{
    AllowedMachines = 'machineAddress'
    OSUsers         = 'osUser'
    Paths           = 'path'
    Hashes          = 'hash'
}

# Permissions the Provider needs on a Safe
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
        Invoke-VaultApi -Session $Session -Method Post -Path "/API/Safes/$([uri]::EscapeDataString($SafeName))/Members" -Body @{
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
        $platform = Invoke-VaultApi -Session $Session -Method Get -Path "/API/Platforms/$([uri]::EscapeDataString($PlatformId))/" -AllowNotFound
        $platformStates[$PlatformId] = if (-not $platform) { 'not found' } elseif ($platform.Active -eq $false) { 'inactive' } else { 'ok' }
    }
    $platformStates[$PlatformId]
}

function New-DemoPassword {
    # Random demo password; the fixed prefix satisfies typical platform complexity rules
    $chars = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    $bytes = New-Object byte[] 16
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    'Aa1!' + -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

function Invoke-Onboarding {
    # Returns one object per AppID + account (AppId, Safe, Object, UserName, Address) with the
    # actual Object name in the Vault, so the product script can print a ready-to-use request.
    param(
        [Parameter(Mandatory)] [hashtable]$Session,
        [Parameter(Mandatory)] [hashtable]$Config
    )

    $appsChanged = $false    # The Provider caches Applications - changes need a restart (or its cache refresh)

    if (-not $Config.SafeOwners) {
        Write-Result info 'No SafeOwners - new Safes are managed only by the logged-on user'
    }

    # --- Applications -------------------------------------------------------
    foreach ($app in $Config.Applications) {
        $appIdEncoded = [uri]::EscapeDataString($app.AppId)

        $existing = (Invoke-VaultApi -Session $Session -Method Get -Path "${appsPath}?AppID=$appIdEncoded").application |
            Where-Object { $_.AppID -eq $app.AppId }

        if ($existing) {
            Write-Result exists "Application '$($app.AppId)'"
        } else {
            $description = if ($app.Description) { $app.Description } else { 'Created by Credential Provider onboarding' }
            Invoke-VaultApi -Session $Session -Method Post -Path $appsPath -Body @{
                application = @{ AppID = $app.AppId; Description = $description; Location = '\Applications' }
            } | Out-Null
            Write-Result created "Application '$($app.AppId)'"
            $appsChanged = $true
        }

        $authPath = "$appsPath/$appIdEncoded/Authentications/"
        $current  = (Invoke-VaultApi -Session $Session -Method Get -Path $authPath).authentication

        foreach ($field in $authTypes.Keys) {
            $type = $authTypes[$field]
            foreach ($value in $app[$field]) {
                if ($current | Where-Object { $_.AuthType -eq $type -and $_.AuthValue -eq $value }) {
                    Write-Result exists "  $type $value"
                } else {
                    Invoke-VaultApi -Session $Session -Method Post -Path $authPath -Body @{
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
    foreach ($safe in $Config.Safes) {
        $safeEncoded = [uri]::EscapeDataString($safe.Name)

        if (Invoke-VaultApi -Session $Session -Method Get -Path "/API/Safes/$safeEncoded" -AllowNotFound) {
            Write-Result exists "Safe '$($safe.Name)'"
        } else {
            Invoke-VaultApi -Session $Session -Method Post -Path '/API/Safes' -Body @{
                safeName    = $safe.Name
                description = 'Created by Credential Provider onboarding'
                managingCPM = ''    # No CPM - demo passwords are not rotated against real targets
            } | Out-Null
            Write-Result created "Safe '$($safe.Name)'"
        }

        $members = (Invoke-VaultApi -Session $Session -Method Get -Path "/API/Safes/$safeEncoded/Members?limit=1000").value

        foreach ($owner in $Config.SafeOwners) {
            $ownerType = if ($owner.Type) { $owner.Type } else { 'User' }
            Add-SafeMemberIfMissing $Session $safe.Name $members $owner.Name $ownerPermissions $ownerType
        }

        foreach ($appId in $safe.AppIds) {
            Add-SafeMemberIfMissing $Session $safe.Name $members $appId $appIdPermissions
        }

        if (-not $safe.Providers) {
            $available = (Invoke-VaultApi -Session $Session -Method Get -Path '/API/Users?componentUser=true&userType=AppProvider').Users.username
            Write-Result warn "  No Providers configured for this Safe. Available: $($available -join ', ')"
        }
        foreach ($provider in $safe.Providers) {
            $found = (Invoke-VaultApi -Session $Session -Method Get -Path "/API/Users?search=$([uri]::EscapeDataString($provider))").Users |
                Where-Object { $_.username -eq $provider }
            if (-not $found) {
                Write-Result warn "  Provider '$provider' not found in the Vault - skipped (install the Provider and re-run)"
                continue
            }
            Add-SafeMemberIfMissing $Session $safe.Name $members $provider $providerPermissions
        }

        $filter   = [uri]::EscapeDataString("safeName eq $($safe.Name)")
        $accounts = (Invoke-VaultApi -Session $Session -Method Get -Path "/API/Accounts?filter=$filter&limit=1000").value

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
                $platformState = Get-PlatformState $Session $account.PlatformId
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

                $created = Invoke-VaultApi -Session $Session -Method Post -Path '/API/Accounts' -Body $body
                Write-Result created "  Account $label (Object: $($created.name))$(if (-not $account.Secret) { ' - random password' })"
                $objectName = $created.name
            }

            # One line per AppID, for the product script to print as a ready-to-use request
            foreach ($appId in $safe.AppIds) {
                [pscustomobject]@{ AppId = $appId; Safe = $safe.Name; Object = $objectName
                                   UserName = $account.UserName; Address = $account.Address }
            }
        }
    }

    if ($appsChanged) {
        Write-Result warn 'Applications changed - the Provider caches them: restart the Provider service on each Provider host to apply the change now'
    }
}
