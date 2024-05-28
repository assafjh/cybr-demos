# Filename: 02-CreateFolders.ps1

# Define the main folder and subfolder paths
$mainFolder = "C:\Central Credential Provider"
$subFolder1 = "$mainFolder\Windows"
$subFolder2 = "$mainFolder\Central Credential Provider Web Service "

# Function to create folders
function Create-Folder {
    param (
        [string]$path
    )
    if (-Not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force
        Write-Host "Created folder: $path"
    } else {
        Write-Host "Folder already exists: $path"
    }
}

# Create the main folder
Create-Folder -path $mainFolder

# Create the subfolders
Create-Folder -path $subFolder1
Create-Folder -path $subFolder2

Write-Host "All folders have been created."
