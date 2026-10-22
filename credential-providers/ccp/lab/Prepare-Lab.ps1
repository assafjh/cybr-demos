# Filename: Prepare-Lab.ps1
# Prepares a lab Windows server for the CCP: installs the IIS features the CCP web service needs,
# shows the .NET Framework version, and binds a self-signed HTTPS certificate on 443 that this
# server trusts. Lab only - not for production. Run it before installing the CCP.
#
# Works in both Windows PowerShell 5.1 and PowerShell 7: it uses appcmd and netsh instead of the
# WebAdministration module, whose objects lose their methods when loaded in PowerShell 7.
# Safe to re-run: the binding is created once, and the certificate on 443 is replaced.
#
# Examples:
#   ./Prepare-Lab.ps1
#   ./Prepare-Lab.ps1 -ExtraNames ccp.lab.local    # More host names on the certificate

#Requires -RunAsAdministrator

param(
    [string[]]$ExtraNames    # Host names clients use, beyond this server's own names
)

$ErrorActionPreference = 'Stop'

# --- .NET Framework and IIS features --------------------------------------------
# .NET Framework 4.x release number -> version (4.8 = 528040)
$release = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
$dotNet  = if ($release -ge 528040) { '4.8 or later' } elseif ($release -ge 461808) { '4.7.2' } else { "older than 4.7.2 (release $release)" }
Write-Host ".NET Framework: $dotNet - check the CCP system requirements for your version"

# IIS features the CCP installation guide lists (Install the Central Credential Provider > Prerequisites)
$features = @(
    'Web-Server'          # IIS 10
    'Web-Net-Ext45'       # .NET Extensibility 4.x
    'Web-ASP'             # ASP
    'Web-Asp-Net45'       # ASP.NET 4.x
    'Web-ISAPI-Ext'       # ISAPI Extensions
    'Web-ISAPI-Filter'    # ISAPI Filters
    'Web-Mgmt-Compat'     # IIS 6 Management Compatibility
    'Web-Metabase'        # IIS 6 Metabase Compatibility
    'Web-Windows-Auth'    # Available for Windows Authentication / Kerberos
)
$result = Install-WindowsFeature -Name $features -IncludeManagementTools
Write-Host "IIS features installed: $($result.Success). Restart needed: $($result.RestartNeeded)"

# --- Self-signed HTTPS certificate ----------------------------------------------
$siteName = 'Default Web Site'
$names    = @(
    [Environment]::MachineName
    [Net.Dns]::GetHostEntry('').HostName    # The name 3-Test-Server.ps1 uses by default
    'localhost'
    $ExtraNames
) | Where-Object { $_ } | ForEach-Object { $_.ToLower() } | Select-Object -Unique

$cert = New-SelfSignedCertificate -DnsName $names -CertStoreLocation Cert:\LocalMachine\My

# HTTPS binding on the site (once)
$appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
if ((& $appcmd list site $siteName) -notmatch 'https/\*:443:') {
    & $appcmd set site $siteName "/+bindings.[protocol='https',bindingInformation='*:443:']" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "appcmd failed to add the HTTPS binding to '$siteName'" }
}

# Attach the certificate to port 443 (replaces a previous one)
netsh http delete sslcert ipport=0.0.0.0:443 2>&1 | Out-Null
netsh http add sslcert ipport=0.0.0.0:443 certhash=$($cert.Thumbprint) certstorename=MY `
    appid='{4dc3e181-e14b-4a21-b022-59fc669b0914}' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'netsh failed to attach the certificate to port 443' }

# Trust it on this server, so PowerShell and the scripts accept it
$store = [Security.Cryptography.X509Certificates.X509Store]::new('Root', 'LocalMachine')
$store.Open('ReadWrite'); $store.Add($cert); $store.Close()

"Certificate $($cert.Thumbprint) bound to https://*:443 for: $($names -join ', ')"
