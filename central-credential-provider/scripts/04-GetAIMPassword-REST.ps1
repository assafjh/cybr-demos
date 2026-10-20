# Filename: 04-GetAIMPassword-REST.ps1
# Works on Windows PowerShell 5.1 and PowerShell 7+

# Configuration variables
$baseUrl = "<ccp-url>/AIMWebService/api/Accounts"
$appID = "AIMWebService"
$safe = "Credential-Providers"
$object = "Database-PostgreSQL-reception"
$folder = "Root"
$reason = "Demo"
$useWindowsAuth = $false # set $true if the CCP IIS app uses Windows Authentication

# Encode parameters (no dependency on System.Web)
$enc = { param($v) [uri]::EscapeDataString($v) }

$url = "${baseUrl}?AppID=$(& $enc $appID)&Safe=$(& $enc $safe)&Object=$(& $enc $object)&Folder=$(& $enc $folder)&Reason=$(& $enc $reason)"
Write-Host "Request URL: $url" -ForegroundColor Cyan

$params = @{
    Uri = $url
    Method = 'GET'
    ErrorAction = 'Stop'
}
if ($useWindowsAuth) { $params.UseDefaultCredentials = $true }

try {
    $response = Invoke-RestMethod @params
    Write-Host "Your password is:" $response.Content -ForegroundColor Green
} catch {
    Write-Host "Request failed:" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "HTTP status:" ([int]$_.Exception.Response.StatusCode) -ForegroundColor Red
    }
    # CCP returns ErrorCode/ErrorMsg in the body - this is the useful part
    if ($_.ErrorDetails.Message) {
        Write-Host "CCP response:" $_.ErrorDetails.Message -ForegroundColor Red
    } else {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
