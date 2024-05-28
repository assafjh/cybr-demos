# Filename: 03-IIS-Enable-WindowsAuthentication.ps1

# Ensure script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You need to run this script as an administrator."
    exit
}

# Import WebAdministration module
Import-Module WebAdministration

# Function to enable Windows Authentication
function Enable-WindowsAuthentication {
    param (
        [string]$SiteName = "Default Web Site"
    )

    try {
        # Install Windows Authentication feature if not already installed
        $feature = Get-WindowsFeature -Name Web-Windows-Auth
        if (-not $feature.Installed) {
            Install-WindowsFeature -Name Web-Windows-Auth
            Write-Host "Windows Authentication feature installed successfully."
        } else {
            Write-Host "Windows Authentication feature is already installed."
        }

        # Enable Windows Authentication at the server level
        Set-WebConfigurationProperty -filter "/system.webServer/security/authentication/windowsAuthentication" -name "enabled" -value "True" -PSPath "IIS:\"
        Write-Host "Windows Authentication enabled at the server level."

        # Enable Windows Authentication for the specified site
        Set-WebConfigurationProperty -filter "/system.webServer/security/authentication/windowsAuthentication" -name "enabled" -value "True" -PSPath "IIS:\Sites\$SiteName"
        Write-Host "Windows Authentication disabled for site: $SiteName."

        # Verify the configuration
        $windowsAuthEnabled = (Get-WebConfigurationProperty -filter "/system.webServer/security/authentication/windowsAuthentication" -name "enabled" -PSPath "IIS:\").Value

        if ($windowsAuthEnabled -eq $true) {
            Write-Host "Windows Authentication is successfully enabled."
        } else {
            Write-Error "Failed to properly configure authentication settings."
        }

    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Enable Windows Authentication for the default website
Enable-WindowsAuthentication -SiteName "Default Web Site"

# Pause to review output (optional)
Start-Sleep -Seconds 5
