# Filename: 2-Test-Vault.ps1
# Checks the Vault side of CCP requests and prints the exact request to use: the AppID and its
# authentication methods, the Safe, Safe members and permissions, the Provider users and the account.
#
# Without parameters it checks every AppID / Safe / account in settings.psd1.
# With -AppId, -Safe and an account it checks that one - e.g. a Safe the customer set up manually.
#
# Read-only - never retrieves or displays passwords. Runs anywhere with access to the PVWA.
# The user needs List Accounts + View Safe Members on the Safe, and Audit Users for the Provider checks.
#
# Examples:
#   ./2-Test-Vault.ps1
#   ./2-Test-Vault.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'settings.psd1'),
    [string]$AppId,
    [string]$Safe,
    [string]$Object,                 # Find the account by Object name,
    [string]$UserName,               # and/or by UserName / Address
    [string]$Address,
    [pscredential]$Credential,       # Optional - otherwise asked once per PowerShell window
    [switch]$NewCredential           # Ask for the credential again
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/Provider-Common.ps1')
. (Join-Path $PSScriptRoot '../common/VaultAccess.ps1')

$session = $null
try {
    $required = if ($AppId -or $Safe) { 'Connection' } else { 'Connection', 'Safes' }
    $config   = Import-ProviderSettings -Path $ConfigPath -Required $required
    $targets  = @(Get-TestTargets -Settings $config -AppId $AppId -Safe $Safe -Object $Object -UserName $UserName -Address $Address)
    if (-not $targets) { throw "No AppID / Safe / account combinations in $ConfigPath" }

    $session = Connect-Vault -Connection $config.Connection -Credential $Credential -NewCredential:$NewCredential
    Write-Host 'Read-only: this script does not change anything in the Vault and never retrieves passwords' -ForegroundColor Cyan

    foreach ($target in $targets) {
        $label = if ($target.Object) { $target.Object } else { "$($target.UserName)@$($target.Address)" }
        Write-Host ''
        Write-Host "=== AppID '$($target.AppId)' / Safe '$($target.Safe)' / $label" -ForegroundColor White

        $found = Test-VaultAccess -Session $session @target
        if ($found) {
            Write-Host 'CCP request - POST /AIMWebService/api/Accounts with body:' -ForegroundColor Cyan
            Write-Host "  $([ordered]@{ AppID = $found.AppId; Safe = $found.Safe; Object = $found.Object } | ConvertTo-Json -Compress)"
            if ($found.UserName -and $found.Address) {
                Write-Host "  $([ordered]@{ AppID = $found.AppId; Safe = $found.Safe; UserName = $found.UserName; Address = $found.Address } | ConvertTo-Json -Compress)"
                Write-Host '  (the second form does not depend on the Object name)' -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "[error]    $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($session) { Disconnect-Vault -Session $session }
}
