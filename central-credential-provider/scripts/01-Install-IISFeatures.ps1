# Filename: 01-Install-IISFeatures.ps1

# Function to get the .NET Framework version
function Get-DotNetVersion {
    $releaseKey = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
    $version = switch ($releaseKey) {
        { $_ -ge 528040 } { "4.8 or later"; break }
        { $_ -ge 461808 } { "4.7.2"; break }
        { $_ -ge 461308 } { "4.7.1"; break }
        { $_ -ge 460798 } { "4.7"; break }
        { $_ -ge 394802 } { "4.6.2"; break }
        { $_ -ge 394254 } { "4.6.1"; break }
        { $_ -ge 393295 } { "4.6"; break }
        { $_ -ge 379893 } { "4.5.2"; break }
        { $_ -ge 378675 } { "4.5.1"; break }
        { $_ -ge 378389 } { "4.5"; break }
        default { "Version not found"; break }
    }
    return $version
}

# Get the .NET Framework version
$dotNetVersion = Get-DotNetVersion
Write-Host "Detected .NET Framework Version: $dotNetVersion"

# Define the features to install
$features = @(
    "Web-Server",
    "Web-Asp-Net",
    "Web-Net-Ext45",  # .NET Extensibility 4.x covers 4.5 and later
    "Web-Asp-Net45",
    "Web-ISAPI-Ext",
    "Web-ISAPI-Filter",
    "Web-Mgmt-Compat"
)

# Install IIS features
Write-Host "Installing IIS features..."
Install-WindowsFeature -Name $features -IncludeAllSubFeature -IncludeManagementTools

# Check installation result
if ($?) {
    Write-Host "IIS features installed successfully."
} else {
    Write-Host "Failed to install IIS features."
}
