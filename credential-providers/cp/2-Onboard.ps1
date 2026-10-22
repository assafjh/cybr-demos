# Filename: 2-Onboard.ps1
# Creates what the CP needs in the Vault, as described in settings.psd1: the application AppIDs
# and their authentication methods, Safes, Safe members and accounts.
# Prints a ready-to-use CP query per account (CLIPasswordSDK).
# Run it after installing the CP, so the Provider user exists and can be added to the Safes.
#
# Idempotent - safe to re-run. Never deletes and never overwrites passwords or permissions.
# Works on Windows PowerShell 5.1 and PowerShell 7+, against PAM Self-Hosted or Privilege Cloud.
#
# Examples:
#   ./2-Onboard.ps1
#   ./2-Onboard.ps1 -ConfigPath ./settings-customer.psd1

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'settings.psd1'),
    [pscredential]$Credential,    # Optional - otherwise asked once per PowerShell window
    [switch]$NewCredential        # Ask for the credential again
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/Provider-Common.ps1')
. (Join-Path $PSScriptRoot '../common/Onboarding.ps1')

$session = $null
try {
    $config  = Import-ProviderSettings -Path $ConfigPath -Required Connection, Applications, Safes -Optional SafeOwners
    $session = Connect-Vault -Connection $config.Connection -Credential $Credential -NewCredential:$NewCredential
    $targets = Invoke-Onboarding -Session $session -Config $config

    if ($targets) {
        Write-Host ''
        Write-Result info 'CP query - on the application machine (Windows; on Linux: clipasswordsdk with -p / -o):'
        foreach ($t in $targets) {
            Write-Result info "CLIPasswordSDK GetPassword /p AppDescs.AppID=$($t.AppId) /p Query=""Safe=$($t.Safe);Folder=Root;Object=$($t.Object)"" /o Password"
        }

        Write-Host ''
        Write-Result info 'Test on each CP machine (after the Provider restart above, if one was asked for):'
        foreach ($t in $targets) {
            Write-Host "             Windows: .\4-Test-Server.ps1 -AppId '$($t.AppId)' -Safe '$($t.Safe)' -UserName '$($t.UserName)' -Address '$($t.Address)'"
            Write-Host "             Linux:   sudo ./4-test-server.sh '$($t.AppId)' '$($t.Safe)' '$($t.UserName)' '$($t.Address)'"
        }
    }
} catch {
    Write-Host "[error]    $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($session) { Disconnect-Vault -Session $session }
}
