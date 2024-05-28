# Filename: 05-GetPassword-SOAP.ps1

# Define CCP URL
$ccp = "http://ajh-vault-components-01"

# Define SOAP request attributes as variables
$AppID = "AIMWebService"
$Safe = "Demo-Safe-General"
$Folder = "Root"
$Object = "Misc-SampleGroup (1)"
$Reason = "Demo"
$ConnectionTimeout = 30

function Format-XML {
    param([string]$xml)

    $doc = New-Object System.Xml.XmlDocument
    $doc.LoadXml($xml)
    $stringWriter = New-Object System.IO.StringWriter
    $xmlWriter = New-Object System.Xml.XmlTextWriter $stringWriter
    $xmlWriter.Formatting = "indented"
    $doc.WriteContentTo($xmlWriter)
    $xmlWriter.Flush()
    $stringWriter.Flush()
    return $stringWriter.ToString()
}

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

# Output the response
Format-XML -xml $response
