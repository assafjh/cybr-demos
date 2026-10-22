# Filename: New-CCPLabCertificate.ps1
# Creates a self-signed certificate for the CCP lab server, binds it to HTTPS (443) on
# Default Web Site and trusts it on this server. Lab only - not for production.
#
# Works in both Windows PowerShell 5.1 and PowerShell 7: it uses appcmd and netsh instead of the
# WebAdministration module, whose objects lose their methods when loaded in PowerShell 7.
# Safe to re-run: binding and certificate are only added when missing. A new certificate
# is created only when no valid one covers the host names (e.g. after editing $names).

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$siteName = 'Default Web Site'
$names = @(
    'ajh-ms-lab-01'
    'ajh-ms-lab-01.local'
    'localhost'
    [Net.Dns]::GetHostEntry('').HostName # The name Test-CCPHealth uses by default
) | ForEach-Object { $_.ToLower() } | Select-Object -Unique

# 1. Reuse a valid self-signed certificate that already covers every name, otherwise create one
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {
    $certNames = $_.DnsNameList.Unicode
    $_.Subject -eq $_.Issuer -and $_.NotAfter -gt (Get-Date).AddDays(30) -and
    @($names | Where-Object { $certNames -notcontains $_ }).Count -eq 0
} | Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $cert) {
    $cert = New-SelfSignedCertificate -DnsName $names -CertStoreLocation Cert:\LocalMachine\My
}

# 2a. HTTPS binding on the site (once)
$appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
if ((& $appcmd list site $siteName) -notmatch 'https/\*:443:') {
    & $appcmd set site $siteName "/+bindings.[protocol='https',bindingInformation='*:443:']" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "appcmd failed to add the HTTPS binding to '$siteName'" }
}

# 2b. Attach the certificate to port 443, unless it is already the one there
$bound = netsh http show sslcert ipport=0.0.0.0:443 | Select-String 'Certificate Hash\s*:\s*(\w+)'
$boundHash = if ($bound) { $bound.Matches[0].Groups[1].Value }
if ($boundHash -ne $cert.Thumbprint) { # -ne ignores case
    netsh http delete sslcert ipport=0.0.0.0:443 2>&1 | Out-Null
    netsh http add sslcert ipport=0.0.0.0:443 certhash=$($cert.Thumbprint) certstorename=MY `
        appid='{4dc3e181-e14b-4a21-b022-59fc669b0914}' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'netsh failed to attach the certificate to port 443' }
}

# 3. Trust it on this server (once), so PowerShell and the scripts accept it
if (-not (Test-Path "Cert:\LocalMachine\Root\$($cert.Thumbprint)")) {
    $store = [Security.Cryptography.X509Certificates.X509Store]::new('Root', 'LocalMachine')
    $store.Open('ReadWrite'); $store.Add($cert); $store.Close()
}

"Certificate $($cert.Thumbprint) bound to https://*:443 for: $($names -join ', ')"