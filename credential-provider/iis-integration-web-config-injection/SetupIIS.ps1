# Step 1: Install IIS and Required Features
Install-WindowsFeature -Name Web-Server, Web-Scripting-Tools, Web-Asp-Net45, Web-Mgmt-Tools, Web-Net-Ext45, Web-ISAPI-Ext, Web-ISAPI-Filter -IncludeManagementTools

# Step 2: Verify IIS Installation
if (Get-WindowsFeature -Name Web-Server | Where-Object Installed) {
    Write-Host "IIS is successfully installed." -ForegroundColor Green
} else {
    Write-Host "IIS installation failed." -ForegroundColor Red
    Exit
}

# Step 3: Deploy the Application Files
$appPath = "C:\inetpub\wwwroot\DemoApp"
if (!(Test-Path -Path $appPath)) {
    New-Item -ItemType Directory -Path $appPath
    Write-Host "Created application directory: $appPath" -ForegroundColor Green
} else {
    Write-Host "Application directory already exists: $appPath" -ForegroundColor Yellow
}

# Create the index.aspx file
$indexAspxPath = Join-Path $appPath "index.aspx"
@"
<%@ Page Language="C#" %>
<html>
<body>
  <h1>Welcome to DemoApp</h1>
  <p>PostgreSQL Password: <%= System.Configuration.ConfigurationManager.AppSettings["PG_PASSWORD"] %></p>
</body>
</html>
"@ | Set-Content -Path $indexAspxPath
Write-Host "Created index.aspx file." -ForegroundColor Green

# Create the web.config file
$webConfigPath = Join-Path $appPath "web.config"
@"
<configuration>
  <appSettings>
    <add key="PG_PASSWORD" value="{{DB_PASSWORD}}" />
  </appSettings>
  <system.web>
    <compilation debug="true" targetFramework="4.8" />
    <httpRuntime targetFramework="4.8" />
  </system.web>
</configuration>
"@ | Set-Content -Path $webConfigPath
Write-Host "Created web.config file." -ForegroundColor Green

# Step 4: Copy UpdateSecrets.ps1 to Scripts Folder
$scriptSourcePath = ".\UpdateSecrets.ps1"  # Path to the UpdateSecrets.ps1 file
$scriptDir = "C:\Scripts"                                # Destination directory
$scriptDestPath = Join-Path $scriptDir "UpdateSecrets.ps1"

# Ensure the destination folder exists
if (!(Test-Path -Path $scriptDir)) {
    New-Item -ItemType Directory -Path $scriptDir
    Write-Host "Created directory for scripts: $scriptDir" -ForegroundColor Green
}

# Copy the UpdateSecrets.ps1 file
if (Test-Path -Path $scriptSourcePath) {
    Copy-Item -Path $scriptSourcePath -Destination $scriptDestPath -Force
    Write-Host "Copied UpdateSecrets.ps1 to $scriptDir." -ForegroundColor Green
} else {
    Write-Host "Source UpdateSecrets.ps1 not found at $scriptSourcePath!" -ForegroundColor Red
    Exit 1
}

# Step 5: Create a New IIS Site
$siteName = "DemoApp"
$port = 8080
$ipAddress = "*"
if (!(Get-Website | Where-Object Name -eq $siteName)) {
    New-Website -Name $siteName -PhysicalPath $appPath -Port $port -IPAddress $ipAddress -HostHeader ""
    Write-Host "Created IIS site: $siteName, bound to port $port." -ForegroundColor Green
} else {
    Write-Host "IIS site '$siteName' already exists." -ForegroundColor Yellow
}

# Step 6: Set Permissions for Application Directory
$acl = Get-Acl $appPath
$permission = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.SetAccessRule($permission)
Set-Acl -Path $appPath -AclObject $acl
Write-Host "Set permissions for IIS_IUSRS on $appPath." -ForegroundColor Green

# Step 7: Restart IIS and Register ASP.NET
$aspNetRegPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe"
if (Test-Path $aspNetRegPath) {
    & $aspNetRegPath -i
    Write-Host "ASP.NET 4.8 registered successfully." -ForegroundColor Green
} else {
    Write-Host "ASP.NET registration tool not found!" -ForegroundColor Red
}

# Restart IIS service asynchronously
if ((Get-Service -Name W3SVC).Status -eq 'Running') {
    Restart-Service W3SVC -Force
    Write-Host "IIS service restarted." -ForegroundColor Green
} else {
    Write-Host "IIS service is not running. Starting the service..." -ForegroundColor Yellow
    Start-Service W3SVC
    Write-Host "IIS service started." -ForegroundColor Green
}

# Step 8: Attach a Task Scheduler Event to IIS App Pool Recycling
$taskName = "UpdateDemoAppSecrets"

# Check if the task already exists
if (Get-ScheduledTask | Where-Object TaskName -eq $taskName) {
    Write-Host "Task '$taskName' already exists. Removing and recreating it..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$scriptDestPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Update web.config secrets for DemoApp"
Write-Host "Scheduled task '$taskName' created successfully." -ForegroundColor Green

# Completion Message
Write-Host "IIS installation and configuration completed successfully!" -ForegroundColor Cyan
