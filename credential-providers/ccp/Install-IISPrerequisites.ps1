# Filename: Install-IISPrerequisites.ps1
# Installs the IIS features the CCP web service needs and shows the .NET Framework version.
# Run on the CCP server before installing the CCP. Safe to re-run - installed features are skipped.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

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
