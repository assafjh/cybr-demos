# Filename: 05-GetPassword-SOAP.ps1

# Define CCP URL
$ccp = "http://<ccp-url>"

# Define SOAP request attributes as variables
$AppID = "AIMWebService" 
$Safe = "Credential-Providers"
$Folder = "Root"
$Object = "Database-PostgreSQL-reception"
$Reason = "Demo"
$ConnectionTimeout = 30

# Account property we want to extract from the response
$accountProperty = "Content"

# Define the SOAP request XML
$soapRequest = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetPassword xmlns="https://tempuri.org/">
      <passwordWSRequest>
        <AppID>$AppID</AppID>
        <Safe>$Safe</Safe>
        <Folder>$Folder</Folder>
        <Object>$Object</Object>
        <Reason>$Reason</Reason>
        <ConnectionTimeout>$ConnectionTimeout</ConnectionTimeout>
      </passwordWSRequest>
    </GetPassword>
  </soap:Body>
</soap:Envelope>
"@

# Define the headers
$headers = @{
    'Content-Type' = 'text/xml; charset=utf-8'
    'SOAPAction' = 'https://tempuri.org/GetPassword'
}

# Define the URL
$url = "${ccp}/AIMWebService/v1.1/AIM.asmx"

# Make the web request
$response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body $soapRequest

# Parse the response XML
$xmlDoc = [xml]$response.Content

# Define namespaces
$namespaceManager = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
$namespaceManager.AddNamespace("soap", "http://schemas.xmlsoap.org/soap/envelope/")
$namespaceManager.AddNamespace("t", "https://tempuri.org/")

# Extract the specified account property
$contentNode = $xmlDoc.SelectSingleNode("//t:GetPasswordResponse/t:GetPasswordResult/t:$accountProperty", $namespaceManager)

if ($contentNode -ne $null) {
    Write-Host "${accountProperty}: $($contentNode.InnerText)" -ForegroundColor Green
} else {
    Write-Host "$accountProperty key not found in the response." -ForegroundColor Red
}
