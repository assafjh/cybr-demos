# Filename: 06-GetCCPCredential-Module.ps1
# Retrieves a password from the Central Credential Provider (CCP) using the
# community CredentialRetriever module (https://github.com/pspete/CredentialRetriever).
# Works on Windows PowerShell 5.1 and PowerShell 7+.

# Configuration variables
$ccpUrl = "https://<ccp-host>" # Base URL only - the module appends /AIMWebService/api/Accounts
$webServiceName = "AIMWebService" # IIS application name of the CCP web service
$appID = "AIMWebService"
$safe = "Credential-Providers"
$object = "Database-PostgreSQL-reception"
$folder = "Root"
$reason = "Demo"

# Authentication options (set according to the CCP IIS configuration)
$useWindowsAuth = $false # $true if the CCP IIS app uses Windows Authentication
$certificateThumbprint = "" # Client certificate thumbprint, if the CCP requires certificate authentication

# Ensure the CredentialRetriever module is installed and loaded
if (-not (Get-Module -ListAvailable -Name CredentialRetriever)) {
    Write-Host "CredentialRetriever module not found - installing for the current user..." -ForegroundColor Yellow
    try {
        Install-Module -Name CredentialRetriever -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
        Write-Host "Failed to install CredentialRetriever:" $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}
Import-Module CredentialRetriever -ErrorAction Stop

# Build the request parameters
$params = @{
    URL = $ccpUrl
    WebServiceName = $webServiceName
    AppID = $appID
    Safe = $safe
    Object = $object
    Folder = $folder
    Reason = $reason
    ErrorAction = 'Stop'
}
if ($useWindowsAuth) { $params.UseDefaultCredentials = $true }
if ($certificateThumbprint) { $params.CertificateThumbPrint = $certificateThumbprint }

# Retrieve the credential
try {
    $result = Get-CCPCredential @params
    Write-Host "Username:" $result.UserName -ForegroundColor Green
    Write-Host "Your password is:" $result.Content -ForegroundColor Green

    # The result can also be converted for use in other cmdlets, e.g.:
    # $psCredential = $result.ToCredential()
} catch {
    Write-Host "Request failed:" -ForegroundColor Red
    # CredentialRetriever surfaces the CCP ErrorCode / ErrorMsg in the exception message
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "CCP response:" $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
