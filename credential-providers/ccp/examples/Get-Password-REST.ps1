# Filename: Get-Password-REST.ps1
# How an application retrieves a password from the Central Credential Provider - REST (POST).
# The CCP URL, AppID, Safe and account come from the settings file (the first Safe with an AppID).
# POST keeps the query parameters out of the URL (and out of IIS / proxy logs).
# Works on Windows PowerShell 5.1 and PowerShell 7+

# Examples:
#   ./Get-Password-REST.ps1   # Uses ../settings.psd1
#   ./Get-Password-REST.ps1 -ConfigPath ../settings-customer.psd1

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../settings.psd1'),
    [switch]$SkipCertificateCheck
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../common/Provider-Common.ps1')

$settings = Import-ProviderSettings -Path $ConfigPath -Required Ccp, Safes
$safe = $settings.Safes | Where-Object { $_.AppIds } | Select-Object -First 1
$account = @($safe.Accounts)[0]
$options = Get-CCPRequestOptions -SkipCertificateCheck:($SkipCertificateCheck -or $settings.Ccp.SkipCertificateCheck -eq $true)

# --- The request an application sends ------------------------------------------
$url = "$($settings.Ccp.Url.TrimEnd('/'))/$($settings.Ccp.WebServiceName)/api/Accounts"
$request = [ordered]@{
    AppID = @($safe.AppIds)[0]
    Safe = $safe.Name
    UserName = $account.UserName # Or: Object = '<object name>'
    Address = $account.Address
    Reason = 'Demo'
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body ($request | ConvertTo-Json) `
        -UseDefaultCredentials:($settings.Ccp.UseDefaultCredentials -eq $true) @options
    Write-Host "Your password is:" $response.Content -ForegroundColor Green
} catch {
    # The CCP returns ErrorCode / ErrorMsg in the body - this is the useful part
    $status = [int]$_.Exception.Response.StatusCode
    $detail = $_.Exception.Message
    try {
        $ccpError = $_.ErrorDetails.Message | ConvertFrom-Json
        $detail = "$($ccpError.ErrorCode): $($ccpError.ErrorMsg)"
    } catch { }
    Write-Host "Request failed (HTTP $status) - $detail" -ForegroundColor Red
}
