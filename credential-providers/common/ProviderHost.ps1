# Filename: ProviderHost.ps1
# Shared by the CP and CCP server checks - dot-source it on the Provider machine.
# Checks the Provider service, its install folder, connectivity to the Vault from Vault.ini and
# recent errors in the Provider logs, and explains Provider error codes.

# The Provider service, by its display name - used in the hints so they show the exact command
$providerServiceName = '*Application Password Provider*'    # CyberArk or Idira branding
$restartProvider     = "Restart-Service -DisplayName '$providerServiceName'"

# Provider error codes -> what to check (from the CyberArk Credential Providers message documentation)
$providerErrorHints = [ordered]@{
    'AIMWS031E'               = 'The AppID parameter is missing - check that the request parameters are not empty'
    'AIMWS030E'               = 'Invalid query format - check how the request parameters are encoded'
    'APPAP22[7-9]E|APPAP230E' = 'More than one account matches - add Object, or narrow the query with UserName and Address'
    'APPAP007E|APPBC007E'     = 'The Provider cannot reach the Vault - check the Provider service and the network to the Vault'
    'APPAP133E|APPAP306E'     = "The AppID authentication failed - the APPAudit.log line shows the values this machine sent. Add its private IP (Allowed Machines), OS user or path to the AppID, then restart the Provider - it caches Applications: $restartProvider"
    'APPAP425E'               = 'The AppID does not exist in the Vault - check the AppID name against 3-Test-Vault.ps1'
    'APPAP307E'               = "The CCP web service AppID (AIMWebService) failed authentication - its Allowed Machines must include this server private IP / host name (see APPAP133E in APPAudit.log). Then restart the Provider: $restartProvider"
    'APPAP004E'               = "Object not found, or the AppID / Provider user has no permission on it - run 3-Test-Vault.ps1 for this AppID and Safe. Just added the Provider to the Safe? Restart it - it caches Safe permissions: $restartProvider"
    'APPAP093E|APPAP127E'     = 'The Provider user is missing the Audit Users authorization, or its user type is not AppProvider'
    'APPAP282E'               = 'The CPM is changing this password right now - retry in a moment'
    'APPEX003E'               = 'General Provider error - often an authentication failure (APPAP306E / APPAP307E). The reason is in APPAudit.log on the Provider machine'
}

function Get-ProviderErrorHint {
    # The hint for a Provider error code, or $null when it is not a known one
    param([string]$Code)
    foreach ($pattern in $providerErrorHints.Keys) {
        if ($Code -match "^($pattern)$") { return $providerErrorHints[$pattern] }
    }
}

function Test-TcpPort {
    param([string]$HostName, [int]$Port)
    $client = [Net.Sockets.TcpClient]::new()
    try   { $client.ConnectAsync($HostName, $Port).Wait(3000) -and $client.Connected }
    catch { $false }
    finally { $client.Dispose() }
}

function Get-ProviderService {
    # The CyberArk / Idira Application Password Provider service, or $null
    Get-Service -DisplayName $providerServiceName -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Find-ProviderPath {
    # The Provider install folder - 64-bit or 32-bit Program Files
    "$env:ProgramFiles\CyberArk\ApplicationPasswordProvider", "${env:ProgramFiles(x86)}\CyberArk\ApplicationPasswordProvider" |
        Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Test-ProviderService {
    $service = Get-ProviderService
    if (-not $service) {
        Write-Result fail 'Provider service not found' -Hint 'Is the Credential Provider installed on this machine?'
    } elseif ($service.Status -ne 'Running') {
        Write-Result fail "Provider service '$($service.DisplayName)' is $($service.Status)" -Hint "Start it: Start-Service -DisplayName '$providerServiceName' - if it stops again, APPConsole.log has the reason"
    } else {
        Write-Result ok "Provider service '$($service.DisplayName)' is running"
    }
}

function Test-ProviderInstall {
    # Vault connectivity from Vault.ini and recent errors in the Provider logs
    param([string]$ProviderPath)

    # --- Registered in the Vault? ------------------------------------------------
    # The installer reports success even when it could not create the Provider in the Vault - CreateEnv.log tells
    $createEnvLog = if ($ProviderPath) { Get-ChildItem $ProviderPath -Recurse -Filter CreateEnv.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1 }
    if (-not $createEnvLog) {
        Write-Result skip 'Provider registration - CreateEnv.log not found under the Provider folder'
    } else {
        $envErrors = Get-Content $createEnvLog.FullName | Where-Object { $_ -match '\b[A-Z]{3,6}\d{3}E\b|Error occurred' }
        if ($envErrors) {
            Write-Result warn "CreateEnv.log - the Provider may not have been created in the Vault. Latest:" `
                -Hint 'Check that the Provider user exists in the Vault (3-Test-Vault.ps1). If not: user names are at most 28 characters - repair the installation with a shorter Provider user name'
            $envErrors | Select-Object -Last 2 | ForEach-Object { Write-Host "             $_" }
        } else {
            Write-Result ok 'Provider registered in the Vault (CreateEnv.log has no errors)'
        }
    }

    # --- Vault connectivity ----------------------------------------------------
    $vaultIni = if ($ProviderPath) { Get-ChildItem $ProviderPath -Recurse -Filter Vault.ini -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
    if (-not $vaultIni) {
        Write-Result skip 'Vault connectivity - Vault.ini not found under the Provider folder' -Hint 'Use -ProviderPath with the Provider install folder'
    } else {
        $ini       = Get-Content $vaultIni
        $addresses = (($ini | Where-Object { $_ -match '^\s*ADDRESS\s*=' }) -replace '^\s*ADDRESS\s*=\s*', '') -split ',' | ForEach-Object { $_.Trim() }
        $portLine  = ($ini | Where-Object { $_ -match '^\s*PORT\s*=' }) -replace '^\s*PORT\s*=\s*', ''
        $port      = if ($portLine) { [int]$portLine } else { 1858 }

        foreach ($vault in $addresses) {
            if (Test-TcpPort $vault $port) {
                Write-Result ok "Vault $($vault):$port is reachable"
            } else {
                Write-Result fail "Vault $($vault):$port is not reachable" -Hint 'Check the firewall / security group from this machine to the Vault'
            }
        }
    }

    # --- Provider logs ---------------------------------------------------------
    # APPConsole.log has service errors; APPAudit.log has the reason each request failed (e.g. APPAP133E)
    foreach ($logName in 'APPConsole.log', 'APPAudit.log') {
        if (-not $ProviderPath) { Write-Result skip "$logName - Provider install folder not found (use -ProviderPath)"; continue }
        $log = Join-Path $ProviderPath "Logs\$logName"
        if (-not (Test-Path $log)) {
            Write-Result skip "$logName - not found under $ProviderPath\Logs"
            continue
        }
        $errors = Get-Content $log -Tail 300 | Where-Object { $_ -match '\b[A-Z]{3,6}\d{3}E\b' }
        if (-not $errors) {
            Write-Result ok "$logName - no errors in the last 300 lines"
        } else {
            Write-Result warn "$logName - $(@($errors).Count) error lines in the last 300 lines. Latest:"
            $errors | Select-Object -Last 3 | ForEach-Object { Write-Host "             $_" }
        }
    }
}

function Write-LastAuditError {
    # After a failed request: the latest error in APPAudit.log - it holds the actual reason. When the
    # request returned only the generic APPEX003E (-Code), the hint for the specific code is shown with it.
    param([string]$ProviderPath, [string]$Code)
    $auditLog = if ($ProviderPath) { Join-Path $ProviderPath 'Logs\APPAudit.log' }
    if (-not ($auditLog -and (Test-Path $auditLog))) { return }

    Start-Sleep -Milliseconds 500    # Let the Provider write the entry
    $reason = Get-Content $auditLog -Tail 20 | Where-Object { $_ -match '\b[A-Z]{3,6}\d{3}E\b' } | Select-Object -Last 1
    if (-not $reason) { return }

    $hint = $null
    if ($Code -eq 'APPEX003E') {
        $specific = ([regex]::Matches($reason, '\b[A-Z]{3,6}\d{3}E\b') | Select-Object -Last 1).Value
        $hint = Get-ProviderErrorHint $specific
    }
    if ($reason -match 'Failure reason: (.*)$') { $reason = $Matches[1] }
    Write-Result info "APPAudit.log: $reason" -Hint $hint
}
