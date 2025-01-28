# Step 1: Set the path and parameters
$cliPath = "C:\Program Files\CyberArk\ApplicationPasswordSdk\CLIPasswordSDK.exe"  # Path to the binary
$appID = "AIMWebService"                                                         # Your AppID
$safe = "Credential-Providers"                                                  # Safe name
$object = "Database-PostgreSQL-reception"                                       # Object name

# Step 2: Construct the command
$secretCommand = "& `"$cliPath`" GetPassword /p AppDescs.AppID=$appID /p Query=`"Safe=$safe;Object=$object`" /o Password"

# Step 3: Execute the command and capture the output
try {
    $secret = Invoke-Expression $secretCommand
} catch {
    Write-Host "Error executing the command: $($_.Exception.Message)" -ForegroundColor Red
    Exit 1
}

# Step 4: Check if the secret was retrieved successfully
if ([string]::IsNullOrEmpty($secret)) {
    Write-Host "Failed to retrieve the secret from the Vault!" -ForegroundColor Red
    Exit 1
}

Write-Host "Successfully retrieved the secret from the Vault!" -ForegroundColor Green

# Step 5: Decrypt the web.config
try {
    $aspnetRegiisPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe"
    & $aspnetRegiisPath -pdf "appSettings" "C:\inetpub\wwwroot\DemoApp"
    Write-Host "Decrypted the appSettings section in web.config!" -ForegroundColor Green
} catch {
    Write-Host "Failed to decrypt the appSettings section in web.config!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Exit 1
}

# Step 6: Update web.config
$configPath = "C:\inetpub\wwwroot\DemoApp\web.config"

try {
    # Read the web.config file
    $configContent = Get-Content $configPath

    # Replace the placeholder with the retrieved secret
    $configContent = $configContent -replace "{{DB_PASSWORD}}", $secret

    # Save the updated web.config file
    Set-Content $configPath $configContent
    Write-Host "Updated the web.config file with the secret!" -ForegroundColor Green
} catch {
    Write-Host "Failed to update the web.config file!" -ForegroundColor Red
    Exit 1
}

# Step 7: Encrypt sensitive section in web.config
try {
    & $aspnetRegiisPath -pe "appSettings" -app "/DemoApp"
    Write-Host "Encrypted the appSettings section in web.config!" -ForegroundColor Green
} catch {
    Write-Host "Failed to encrypt the appSettings section!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Exit 1
}

# Step 8: Restart the Application Pool for DemoApp
try {
    Import-Module WebAdministration
    $appPoolName = "DefaultAppPool" # Replace with the specific app pool name if different
    Restart-WebAppPool -Name $appPoolName
    Write-Host "Restarted the application pool '$appPoolName'!" -ForegroundColor Green
} catch {
    Write-Host "Failed to restart the application pool!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

