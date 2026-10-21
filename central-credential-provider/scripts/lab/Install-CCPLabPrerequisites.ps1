# Filename: Install-CCPLabPrerequisites.ps1
# Installs the IIS features the CCP web service needs and shows the .NET Framework version.
# Lab only - run before installing the Credential Provider and the CCP web service.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# .NET Framework 4.x release number -> version (4.8 = 528040)
$release = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
$dotNet  = if ($release -ge 528040) { '4.8 or later' } elseif ($release -ge 461808) { '4.7.2' } else { "older than 4.7.2 (release $release)" }
Write-Host ".NET Framework: $dotNet - check the CCP system requirements for your version"

$features = @(
    'Web-Server'
    'Web-Asp-Net'
    'Web-Net-Ext45'
    'Web-Asp-Net45'
    'Web-ISAPI-Ext'
    'Web-ISAPI-Filter'
    'Web-Mgmt-Compat'
)

$result = Install-WindowsFeature -Name $features -IncludeAllSubFeature -IncludeManagementTools
Write-Host "IIS features installed: $($result.Success). Restart needed: $($result.RestartNeeded)"
