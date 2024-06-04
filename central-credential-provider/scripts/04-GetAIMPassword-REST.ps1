# Filename: 04-GetAIMPassword-REST.ps1

# Configuration variables
$baseUrl = "<ccp-url>/AIMWebService/api/Accounts"
$appID = "AIMWebService"
$safe = "Credential-Providers"
$object = "Database-PostgreSQL-reception"
$folder = "Root"
$reason = "Demo"

# Construct the full URL with parameters, ensuring proper encoding
$appIDEncoded = [System.Web.HttpUtility]::UrlEncode($appID)
$safeEncoded = [System.Web.HttpUtility]::UrlEncode($safe)
$objectEncoded = [System.Web.HttpUtility]::UrlEncode($object)
$folderEncoded = [System.Web.HttpUtility]::UrlEncode($folder)
$reasonEncoded = [System.Web.HttpUtility]::UrlEncode($reason)

$url = "${baseUrl}?AppID=$appIDEncoded&Safe=$safeEncoded&Object=$objectEncoded&Folder=$folderEncoded&Reason=$reasonEncoded"

# Make the web request with NTLM authentication
try {
    $response = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json"
    Write-Host "Your password is:" $response.content -ForegroundColor Green
} catch {
    Write-Host "Request failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    # Print full exception details
    $errorMessage = $_.Exception | Out-String
    Write-Host $errorMessage -ForegroundColor Red
}
