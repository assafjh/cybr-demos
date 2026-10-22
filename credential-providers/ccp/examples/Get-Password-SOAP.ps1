# Filename: Get-Password-SOAP.ps1
# How an application retrieves a password from the Central Credential Provider - SOAP (legacy).
# Prefer REST (Get-Password-REST.ps1) - SOAP is here for applications that still use it.
# The CCP URL, AppID, Safe and account come from the settings file (the first Safe with an AppID).
# Works on Windows PowerShell 5.1 and PowerShell 7+

# Examples:
#   ./Get-Password-SOAP.ps1   # Uses ../settings.psd1
#   ./Get-Password-SOAP.ps1 -ConfigPath ../settings-customer.psd1

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
$url = "$($settings.Ccp.Url.TrimEnd('/'))/$($settings.Ccp.WebServiceName)/v1.1/AIM.asmx"
$appId = [Security.SecurityElement]::Escape(@($safe.AppIds)[0])
$query = [Security.SecurityElement]::Escape("Safe=$($safe.Name);UserName=$($account.UserName);Address=$($account.Address)")

$soapRequest = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetPassword xmlns="https://tempuri.org/">
      <passwordWSRequest>
        <AppID>$appId</AppID>
        <Query>$query</Query>
        <Reason>Demo</Reason>
        <ConnectionTimeout>30</ConnectionTimeout>
      </passwordWSRequest>
    </GetPassword>
  </soap:Body>
</soap:Envelope>
"@

try {
    $response = Invoke-WebRequest -Uri $url -Method Post -Body $soapRequest -UseBasicParsing `
        -Headers @{ SOAPAction = 'https://tempuri.org/GetPassword' } -ContentType 'text/xml; charset=utf-8' `
        -UseDefaultCredentials:($settings.Ccp.UseDefaultCredentials -eq $true) @options

    $xml = [xml]$response.Content
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('t', 'https://tempuri.org/')
    Write-Host "Your password is:" $xml.SelectSingleNode('//t:GetPasswordResult/t:Content', $ns).InnerText -ForegroundColor Green
} catch {
    # SOAP errors come back as a fault - its faultstring holds the CCP error code and message.
    # Windows PowerShell 5.1 returns the raw XML; PowerShell 7 returns its text without the tags.
    $fault = $_.ErrorDetails.Message
    $detail = if ($fault -match '<faultstring>(.*?)</faultstring>') { $Matches[1] }
              elseif ($fault) { $fault -replace '^soap:(Server|Client)', '' }
              else { $_.Exception.Message }
    Write-Host "Request failed - $detail" -ForegroundColor Red
}