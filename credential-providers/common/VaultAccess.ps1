# Filename: VaultAccess.ps1
# Shared by the CP and CCP Vault checks (3-Test-Vault.ps1) - dot-source it, then
# call Test-VaultAccess. Checks the AppID and its authentication methods, the Safe, Safe membership and
# permissions of the AppID and of the Provider users, and the account itself (its actual Object name).
#
# Read-only: sends GET requests only and never retrieves or displays passwords.
# A check the logged-on user has no permission for is reported as [skip].

$appsPath = '/WebServices/PIMServices.svc/Applications'

# Permissions the Provider needs on the Safe, with their PVWA names
$appIdPermissions    = [ordered]@{ retrieveAccounts = 'Retrieve accounts'; listAccounts = 'List accounts' }
$providerPermissions = [ordered]@{ retrieveAccounts = 'Retrieve accounts'; listAccounts = 'List accounts'; viewSafeMembers = 'View Safe members' }

function Resolve-Forbidden {
    # A 403 means the user running this script cannot see this part - not that it is misconfigured
    param($ErrorRecord, [string]$What)
    if ($ErrorRecord.Exception.Data['StatusCode'] -eq 403) {
        Write-Result skip "$What - no permission to check it with the user running this script"
    } else {
        throw $ErrorRecord
    }
}

function Test-SafeMember {
    param($Members, [string]$SafeName, [string]$MemberName, [string]$Role, $Required)

    $member = $Members | Where-Object { $_.memberName -eq $MemberName }
    if (-not $member) {
        Write-Result fail "$Role '$MemberName' is not a member of Safe '$SafeName'" `
            -Hint "Add it with: $($Required.Values -join ', ')"
        return
    }

    $missing = $Required.Keys | Where-Object { -not $member.permissions.$_ } | ForEach-Object { $Required[$_] }
    if ($missing) {
        Write-Result fail "$Role '$MemberName' is a member of Safe '$SafeName' but is missing: $($missing -join ', ')" `
            -Hint "Grant: $($missing -join ', ')"
    } else {
        Write-Result ok "$Role '$MemberName' - $($Required.Values -join ', ')"
    }
}

function Test-VaultAccess {
    # All the Vault-side checks for one AppID + Safe + account. Returns the account (AppId, Safe,
    # Object, UserName, Address) when exactly one matches, so the product script can print the request.
    param(
        [Parameter(Mandatory)] [hashtable]$Session,
        [string]$AppId, [string]$Safe, [string]$Object, [string]$UserName, [string]$Address
    )

    $safeEncoded = [uri]::EscapeDataString($Safe)
    $members     = $null
    $account     = $null

    # --- AppID ---------------------------------------------------------------
    try {
        $appIdEncoded = [uri]::EscapeDataString($AppId)
        $app = (Invoke-VaultApi -Session $Session -Method Get -Path "${appsPath}?AppID=$appIdEncoded").application |
            Where-Object { $_.AppID -eq $AppId }

        if (-not $app) {
            Write-Result fail "AppID '$AppId' not found" -Hint 'Check the AppID name, or create it under Applications'
        } elseif ($app.Disabled -eq $true) {
            Write-Result fail "AppID '$AppId' is disabled" -Hint 'Enable the application'
        } else {
            $auth = (Invoke-VaultApi -Session $Session -Method Get -Path "$appsPath/$appIdEncoded/Authentications/").authentication
            if ($auth) {
                Write-Result ok "AppID '$AppId' - $(($auth | ForEach-Object { "$($_.AuthType): $($_.AuthValue)" }) -join ', ')"
            } else {
                Write-Result warn "AppID '$AppId' has no authentication methods - any machine can retrieve with it"
            }
        }
    } catch { Resolve-Forbidden $_ "AppID '$AppId'" }

    # --- Safe and members ----------------------------------------------------
    try {
        if (-not (Invoke-VaultApi -Session $Session -Method Get -Path "/API/Safes/$safeEncoded" -AllowNotFound)) {
            Write-Result fail "Safe '$Safe' not found" `
                -Hint 'Check the Safe name, and that the user running this script is a member of it'
            return
        }
        Write-Result ok "Safe '$Safe'"

        $members = (Invoke-VaultApi -Session $Session -Method Get -Path "/API/Safes/$safeEncoded/Members?limit=1000").value
        Test-SafeMember $members $Safe $AppId 'AppID' $appIdPermissions
    } catch { Resolve-Forbidden $_ "Members of Safe '$Safe'" }

    # --- Provider users ------------------------------------------------------
    if ($null -eq $members) {
        Write-Result skip 'Provider users - Safe members could not be read'
    } else {
        try {
            $providers = (Invoke-VaultApi -Session $Session -Method Get -Path '/API/Users?componentUser=true&userType=AppProvider').Users
            $inSafe    = $providers | Where-Object { $members.memberName -contains $_.username }

            if (-not $inSafe) {
                Write-Result fail "No Provider user is a member of Safe '$Safe'" `
                    -Hint "Add the Provider user of each CP / CCP host with: $($providerPermissions.Values -join ', ')"
            }
            foreach ($provider in $inSafe) {
                Test-SafeMember $members $Safe $provider.username 'Provider' $providerPermissions

                # Without Audit Users the Provider cannot read the AppID details (APPAP093E)
                $details = Invoke-VaultApi -Session $Session -Method Get -Path "/API/Users/$($provider.id)"
                if ($details.vaultAuthorization -notcontains 'AuditUsers') {
                    Write-Result fail "Provider '$($provider.username)' does not have the Audit Users authorization" `
                        -Hint 'Grant Audit Users to the Provider user'
                }
            }

            $notInSafe = $providers | Where-Object { $members.memberName -notcontains $_.username }
            if ($notInSafe) {
                Write-Result info "Providers that are not members of this Safe: $($notInSafe.username -join ', ')"
            }
        } catch { Resolve-Forbidden $_ 'Provider users' }
    }

    # --- Account ------------------------------------------------------------
    # Note: reads up to 1000 accounts in the Safe - enough for demo and POC Safes
    try {
        $filter   = [uri]::EscapeDataString("safeName eq $Safe")
        $accounts = (Invoke-VaultApi -Session $Session -Method Get -Path "/API/Accounts?filter=$filter&limit=1000").value

        $found = @($accounts | Where-Object {
            (-not $Object   -or $_.name     -eq $Object)   -and
            (-not $UserName -or $_.userName -eq $UserName) -and
            (-not $Address  -or $_.address  -eq $Address)
        })

        switch ($found.Count) {
            0 {
                Write-Result fail 'No account in the Safe matches the given values' `
                    -Hint 'Compare the values with the account properties in the PVWA (the Provider returns APPAP004E)'
            }
            1 {
                $account = $found[0]
                Write-Result ok "Account found - Object: '$($account.name)' (UserName: $($account.userName), Address: $($account.address), Platform: $($account.platformId))"
            }
            default {
                Write-Result fail "$($found.Count) accounts match - the Provider fails with 'too many objects' (APPAP227E)" `
                    -Hint 'Narrow it down: add -Object, or both -UserName and -Address'
                $found | ForEach-Object { Write-Result info "  $($_.name)" }
            }
        }
    } catch { Resolve-Forbidden $_ "Accounts in Safe '$Safe'" }

    if ($account) {
        [pscustomobject]@{ AppId = $AppId; Safe = $Safe; Object = $account.name
                           UserName = $account.userName; Address = $account.address }
    }
}
