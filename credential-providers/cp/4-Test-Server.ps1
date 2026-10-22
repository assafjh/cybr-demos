# Filename: 4-Test-Server.ps1
# Checks the machine side of the Credential Provider: the Provider service, connectivity to the
# Vault, recent errors in the Provider logs, and test retrievals through CLIPasswordSDK with the
# Provider error code explained.
#
# The test retrievals (every AppID / Safe / account) come from the settings file when it exists;
# parameters override them. Without a settings file only the machine checks run.
#
# Read-only: changes nothing. A test retrieval asks for the account's user name - never the password.
# Run it on the CP machine, as administrator. For the Vault side use 3-Test-Vault.ps1.
#
# Examples:
#   ./4-Test-Server.ps1
#   ./4-Test-Server.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'settings.psd1'),
    [string]$ProviderPath,

    # One test retrieval instead of the ones in the settings file
    [string]$AppId,
    [string]$Safe,
    [string]$Object,
    [string]$UserName,
    [string]$Address
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/Provider-Common.ps1')
. (Join-Path $PSScriptRoot '../common/ProviderHost.ps1')

$settings = $null
if (Test-Path $ConfigPath) {
    try {
        $settings = Import-ProviderSettings -Path $ConfigPath
    } catch {
        Write-Result fail $_.Exception.Message
        exit 1
    }
}

Write-Host 'Read-only: this script changes nothing and never displays passwords' -ForegroundColor Cyan
Write-Host ''

# --- Provider service, Vault connectivity, logs ----------------------------------
Test-ProviderService
if (-not $ProviderPath) { $ProviderPath = Find-ProviderPath }
Test-ProviderInstall -ProviderPath $ProviderPath

# --- Test retrievals --------------------------------------------------------------
$cli = 'CyberArk', 'Idira' | ForEach-Object { "$env:ProgramFiles\$_", "${env:ProgramFiles(x86)}\$_" } |
    Where-Object { Test-Path $_ } |
    ForEach-Object { Get-ChildItem $_ -Recurse -Filter 'CLIPasswordSDK*.exe' -ErrorAction SilentlyContinue } |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $cli) {
    Write-Result skip 'Test retrievals - CLIPasswordSDK.exe not found under Program Files'
    return
}

function Test-Retrieval {
    param([hashtable]$Target)

    $query = "Safe=$($Target.Safe);Folder=Root"
    if ($Target.Object)   { $query += ";Object=$($Target.Object)" }
    if ($Target.UserName) { $query += ";UserName=$($Target.UserName)" }
    if ($Target.Address)  { $query += ";Address=$($Target.Address)" }
    Write-Result info "Test retrieval: AppID $($Target.AppId), Query $query"

    # PassProps.UserName returns the account's user name - proves the retrieval without the password
    $output = & $cli GetPassword /p "AppDescs.AppID=$($Target.AppId)" /p "Query=$query" /p 'Reason=CP health check' /o PassProps.UserName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Result ok "Retrieved account '$output' - password not requested"
        return
    }

    $message = "$output".Trim()
    $code = if ($message -match '\b([A-Z]{3,6}\d{3}E)\b') { $Matches[1] }
    $hint = Get-ProviderErrorHint $code
    if (-not $hint) { $hint = 'Look up the error code in the CyberArk Credential Providers documentation' }
    Write-Result fail $message -Hint $hint
    Write-LastAuditError -ProviderPath $ProviderPath

    if ($code -in 'APPAP306E', 'APPEX003E') {
        Write-Result info "Note: this test runs as CLIPasswordSDK ($cli) under your user - an AppID that also checks Path, Hash or OS user accepts only the real application"
    }
}

if (-not ($AppId -or $Safe -or $settings)) {
    Write-Result skip "Test retrievals - no settings file ($ConfigPath) and no -AppId / -Safe given"
    return
}
try {
    $targets = Get-TestTargets -Settings $settings -AppId $AppId -Safe $Safe -Object $Object -UserName $UserName -Address $Address
} catch {
    Write-Result fail "Test retrieval - $($_.Exception.Message)"
    return
}

foreach ($target in $targets) { Test-Retrieval $target }
