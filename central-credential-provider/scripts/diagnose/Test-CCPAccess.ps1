# Filename: Test-CCPAccess.ps1
# Checks the Vault side of CCP requests and prints the exact request to use:
# the AppID and its authentication methods, the Safe, Safe membership and permissions of the
# AppID and of the Provider users, and the account itself (its actual Object name).
#
# Without parameters it checks every AppID / Safe / account in the settings file.
# With -AppId, -Safe and an account it checks that one - e.g. a Safe the customer set up manually.
#
# Read-only: sends GET requests only and never retrieves or displays passwords.
# The user running it needs List Accounts + View Safe Members on the Safe, and Audit Users
# to check the Provider users. A check it has no permission for is reported as [skip].
# Works on Windows PowerShell 5.1 and PowerShell 7+, against PAM Self-Hosted or Privilege Cloud.
#
# Examples:
#   ./Test-CCPAccess.ps1    # Uses ../settings.psd1
#   ./Test-CCPAccess.ps1 -ConfigPath ../settings-customer.psd1
#   ./Test-CCPAccess.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../settings.psd1'),
    [string]$AppId,
    [string]$Safe,
    [string]$Object,                 # Find the account by Object name,
    [string]$UserName,               # and/or by UserName / Address
    [string]$Address,
    [pscredential]$Credential,       # Optional - otherwise asked once per PowerShell window
    [switch]$NewCredential           # Ask for the credential again
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/CCP-Common.ps1')

$appsPath = '/WebServices/PIMServices.svc/Applications'

# Permissions the CCP needs on the Safe, with their PVWA names
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

function Test-CCPTarget {
    # All the checks for one AppID + Safe + account
    param([string]$AppId, [string]$Safe, [string]$Object, [string]$UserName, [string]$Address)

    $safeEncoded = [uri]::EscapeDataString($Safe)
    $members     = $null
    $account     = $null

    # --- AppID ---------------------------------------------------------------
    try {
        $appIdEncoded = [uri]::EscapeDataString($AppId)
        $app = (Invoke-CCPApi -Session $session -Method Get -Path "${appsPath}?AppID=$appIdEncoded").application |
            Where-Object { $_.AppID -eq $AppId }

        if (-not $app) {
            Write-Result fail "AppID '$AppId' not found" -Hint 'Check the AppID name, or create it under Applications'
        } elseif ($app.Disabled -eq $true) {
            Write-Result fail "AppID '$AppId' is disabled" -Hint 'Enable the application'
        } else {
            $auth = (Invoke-CCPApi -Session $session -Method Get -Path "$appsPath/$appIdEncoded/Authentications/").authentication
            if ($auth) {
                Write-Result ok "AppID '$AppId' - $(($auth | ForEach-Object { "$($_.AuthType): $($_.AuthValue)" }) -join ', ')"
            } else {
                Write-Result warn "AppID '$AppId' has no authentication methods - any machine can retrieve with it"
            }
        }
    } catch { Resolve-Forbidden $_ "AppID '$AppId'" }

    # --- Safe and members ----------------------------------------------------
    try {
        if (-not (Invoke-CCPApi -Session $session -Method Get -Path "/API/Safes/$safeEncoded" -AllowNotFound)) {
            Write-Result fail "Safe '$Safe' not found" `
                -Hint 'Check the Safe name, and that the user running this script is a member of it'
            return
        }
        Write-Result ok "Safe '$Safe'"

        $members = (Invoke-CCPApi -Session $session -Method Get -Path "/API/Safes/$safeEncoded/Members?limit=1000").value
        Test-SafeMember $members $Safe $AppId 'AppID' $appIdPermissions
    } catch { Resolve-Forbidden $_ "Members of Safe '$Safe'" }

    # --- Provider users ------------------------------------------------------
    if ($null -eq $members) {
        Write-Result skip 'Provider users - Safe members could not be read'
    } else {
        try {
            $providers = (Invoke-CCPApi -Session $session -Method Get -Path '/API/Users?componentUser=true&userType=AppProvider').Users
            $inSafe    = $providers | Where-Object { $members.memberName -contains $_.username }

            if (-not $inSafe) {
                Write-Result fail "No Provider user is a member of Safe '$Safe'" `
                    -Hint "Add the Provider user of each CCP host with: $($providerPermissions.Values -join ', ')"
            }
            foreach ($provider in $inSafe) {
                Test-SafeMember $members $Safe $provider.username 'Provider' $providerPermissions

                # Without Audit Users the Provider cannot read the AppID details (APPAP093E)
                $details = Invoke-CCPApi -Session $session -Method Get -Path "/API/Users/$($provider.id)"
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
        $accounts = (Invoke-CCPApi -Session $session -Method Get -Path "/API/Accounts?filter=$filter&limit=1000").value

        $found = @($accounts | Where-Object {
            (-not $Object   -or $_.name     -eq $Object)   -and
            (-not $UserName -or $_.userName -eq $UserName) -and
            (-not $Address  -or $_.address  -eq $Address)
        })

        switch ($found.Count) {
            0 {
                Write-Result fail 'No account in the Safe matches the given values' `
                    -Hint 'Compare the values with the account properties in the PVWA (the CCP returns APPAP004E)'
            }
            1 {
                $account = $found[0]
                Write-Result ok "Account found - Object: '$($account.name)' (UserName: $($account.userName), Address: $($account.address), Platform: $($account.platformId))"
            }
            default {
                Write-Result fail "$($found.Count) accounts match - the CCP fails with 'too many objects' (APPAP227E)" `
                    -Hint 'Narrow it down: add -Object, or both -UserName and -Address'
                $found | ForEach-Object { Write-Result info "  $($_.name)" }
            }
        }
    } catch { Resolve-Forbidden $_ "Accounts in Safe '$Safe'" }

    # --- The request to use -------------------------------------------------
    if ($account) {
        Write-Host 'CCP request - POST /AIMWebService/api/Accounts with body:' -ForegroundColor Cyan
        Write-Host "  $([ordered]@{ AppID = $AppId; Safe = $Safe; Object = $account.name } | ConvertTo-Json -Compress)"
        if ($account.userName -and $account.address) {
            Write-Host "  $([ordered]@{ AppID = $AppId; Safe = $Safe; UserName = $account.userName; Address = $account.address } | ConvertTo-Json -Compress)"
            Write-Host '  (the second form does not depend on the Object name)' -ForegroundColor Gray
        }
    }
}

# --- What to check: the given target, or everything in the settings file -------
try {
    $config = Import-CCPSettings -Path $ConfigPath -Required Connection

    if ($AppId -or $Safe) {
        if (-not ($AppId -and $Safe -and ($Object -or $UserName -or $Address))) {
            throw 'Specify -AppId, -Safe and the account (-Object, or -UserName and/or -Address)'
        }
        $targets = @(@{ AppId = $AppId; Safe = $Safe; Object = $Object; UserName = $UserName; Address = $Address })
    } else {
        $config  = Import-CCPSettings -Path $ConfigPath -Required Connection, Safes
        $targets = foreach ($s in $config.Safes) {
            foreach ($a in $s.AppIds) {
                foreach ($acc in $s.Accounts) {
                    @{ AppId = $a; Safe = $s.Name; Object = $acc.Name; UserName = $acc.UserName; Address = $acc.Address }
                }
            }
        }
        if (-not $targets) { throw "No AppID / Safe / account combinations in $ConfigPath" }
    }

    $session = Connect-CCPVault -Connection $config.Connection -Credential $Credential -NewCredential:$NewCredential
} catch {
    Write-Host "[error]    $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host 'Read-only: this script does not change anything in the Vault and never retrieves passwords' -ForegroundColor Cyan

try {
    foreach ($target in $targets) {
        $label = if ($target.Object) { $target.Object } else { "$($target.UserName)@$($target.Address)" }
        Write-Host ''
        Write-Host "=== AppID '$($target.AppId)' / Safe '$($target.Safe)' / $label" -ForegroundColor White
        Test-CCPTarget @target
    }
} catch {
    Write-Host "[error]    $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Disconnect-CCPVault -Session $session
}
