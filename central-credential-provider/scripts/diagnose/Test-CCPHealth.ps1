# Filename: Test-CCPHealth.ps1
# Checks the machine side of the Central Credential Provider: the Provider service, IIS and the
# AIMWebService application, connectivity to the Vault, recent errors in the Provider logs, and
# test retrievals with the CCP error code explained.
#
# The CCP URL and the test retrievals (every AppID / Safe / account) come from the settings file
# when it exists; parameters override them. Without a settings file only the machine checks run,
# unless a test retrieval is given with parameters.
#
# Read-only: changes nothing. A test retrieval reports success only - the password is never displayed.
# Run it on the CCP server, as a local administrator, with Windows PowerShell 5.1 or PowerShell 7+.
# For the Vault side (AppID, Safe members, Object name) use Test-CCPAccess.ps1.
#
# Examples:
#   ./Test-CCPHealth.ps1    # Uses ../settings.psd1
#   ./Test-CCPHealth.ps1 -ConfigPath ../settings-customer.psd1
#   ./Test-CCPHealth.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../settings.psd1'),
    [string]$CcpUrl,                  # Overrides Ccp.Url - the host name must match the CCP certificate
    [string]$WebServiceName,          # Overrides Ccp.WebServiceName
    [string]$ProviderPath = "${env:ProgramFiles(x86)}\CyberArk\ApplicationPasswordProvider",

    # One test retrieval instead of the ones in the settings file
    [string]$AppId,
    [string]$Safe,
    [string]$Object,
    [string]$UserName,
    [string]$Address,
    [switch]$UseDefaultCredentials    # When the CCP uses Windows Authentication
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/CCP-Common.ps1')

# CCP error codes -> what to check (from the CyberArk CCP REST and Provider message documentation)
$errorHints = [ordered]@{
    'AIMWS031E'               = 'The AppID parameter is missing - check that the request parameters are not empty'
    'AIMWS030E'               = 'Invalid query format - check how the request parameters are encoded'
    'APPAP22[7-9]E|APPAP230E' = 'More than one account matches - add Object, or narrow the query with UserName and Address'
    'APPAP007E|APPBC007E'     = 'The Provider cannot reach the Vault - check the Provider service and the network to the Vault'
    'APPAP306E'               = 'Application authentication failed - check the AppID Allowed Machines / OS user / certificate. APPAudit.log (APPAP133E) shows the exact value that was rejected. Already fixed in the Vault? Restart the Provider service - it caches Applications'
    'APPAP307E'               = 'The CCP web service AppID (AIMWebService) failed authentication - its Allowed Machines must include this server private IP / host name (see APPAP133E in APPAudit.log). Then restart the Provider service'
    'APPAP004E'               = 'Object not found, or the AppID / Provider user has no permission on it - run Test-CCPAccess.ps1 for this AppID and Safe'
    'APPAP093E|APPAP127E'     = 'The Provider user is missing the Audit Users authorization, or its user type is not AppProvider'
    'APPAP282E'               = 'The CPM is changing this password right now - retry in a moment'
    'APPEX003E'               = 'General Provider error - the reason is in APPConsole.log on the CCP server (the log check above shows the latest errors)'
}

function Get-ErrorHint {
    param([string]$Code, [int]$Status)
    foreach ($pattern in $errorHints.Keys) {
        if ($Code -match "^($pattern)$") { return $errorHints[$pattern] }
    }
    switch ($Status) {
        401     { 'Authentication required - the CCP may use Windows Authentication (-UseDefaultCredentials) or a client certificate' }
        403     { 'Forbidden - check the AppID authentication methods (Allowed Machines, OS user, certificate)' }
        404     { 'Not found - check the web service name, or run Test-CCPAccess.ps1' }
        default { 'Look up the error code in the CyberArk Credential Providers documentation' }
    }
}

function Test-TcpPort {
    param([string]$HostName, [int]$Port)
    $client = [Net.Sockets.TcpClient]::new()
    try   { $client.ConnectAsync($HostName, $Port).Wait(3000) -and $client.Connected }
    catch { $false }
    finally { $client.Dispose() }
}

# --- Settings: CCP URL, web service name, test retrievals ----------------------
$settings = $null
if (Test-Path $ConfigPath) {
    try {
        $settings = Import-CCPSettings -Path $ConfigPath -Required Ccp
    } catch {
        Write-Result fail $_.Exception.Message
        exit 1
    }
}

function Get-HostName {
    # FQDN when it resolves (the usual certificate name on a CCP server), otherwise the machine name
    try { [Net.Dns]::GetHostEntry('').HostName } catch { [Environment]::MachineName }
}

$baseUrl = if ($CcpUrl) { $CcpUrl } elseif ($settings) { $settings.Ccp.Url } else { "https://$(Get-HostName)" }
$serviceName = if ($WebServiceName) { $WebServiceName } elseif ($settings.Ccp.WebServiceName) { $settings.Ccp.WebServiceName } else { 'AIMWebService' }
$url     = "$($baseUrl.TrimEnd('/'))/$serviceName/api/Accounts"
$useWindowsAuth = $UseDefaultCredentials -or ($settings.Ccp.UseDefaultCredentials -eq $true)

Write-Host 'Read-only: this script changes nothing and never displays passwords' -ForegroundColor Cyan
Write-Host ''

$onWindows = [Environment]::OSVersion.Platform -eq 'Win32NT'

# --- Provider service --------------------------------------------------------
if (-not $onWindows) {
    Write-Result skip 'Machine checks (service, IIS, Vault.ini, log) - not running on Windows'
} else {
    $providerService = Get-Service | Where-Object { $_.DisplayName -like '*Application Password Provider*' } | Select-Object -First 1
    if (-not $providerService) {
        Write-Result fail 'Provider service not found' -Hint 'Is the Credential Provider installed on this server?'
    } elseif ($providerService.Status -ne 'Running') {
        Write-Result fail "Provider service '$($providerService.DisplayName)' is $($providerService.Status)" -Hint 'Start the service and check APPConsole.log for the reason it stopped'
    } else {
        Write-Result ok "Provider service '$($providerService.DisplayName)' is running"
    }

    # --- IIS and the web service ---------------------------------------------
    $w3svc = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
    if (-not $w3svc -or $w3svc.Status -ne 'Running') {
        Write-Result fail 'IIS (W3SVC) is not running' -Hint 'Start the World Wide Web Publishing Service'
    } elseif (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        Write-Result skip 'IIS application check - the WebAdministration module is not available'
    } else {
        Import-Module WebAdministration
        $webApp = Get-WebApplication -Name $serviceName | Select-Object -First 1
        if (-not $webApp) {
            Write-Result fail "IIS application '$serviceName' not found" -Hint 'Check the web service name (Ccp.WebServiceName / -WebServiceName) or the CCP installation'
        } else {
            $poolState = (Get-WebAppPoolState -Name $webApp.applicationPool).Value
            if ($poolState -ne 'Started') {
                Write-Result fail "IIS application '$serviceName' - application pool '$($webApp.applicationPool)' is $poolState" -Hint 'Start the application pool'
            } else {
                Write-Result ok "IIS application '$serviceName' - application pool '$($webApp.applicationPool)' started"
            }

            # The AppID the web service itself uses, and whether it trusts a load balancer's X-Forwarded-For
            $webConfig = Join-Path ([Environment]::ExpandEnvironmentVariables($webApp.PhysicalPath)) 'web.config'
            if (Test-Path $webConfig) {
                $appSettings = ([xml](Get-Content $webConfig -Raw)).configuration.appSettings.add
                $serviceAppId = ($appSettings | Where-Object { $_.key -eq 'AppID' }).value
                $proxies      = ($appSettings | Where-Object { $_.key -eq 'TrustedProxies' }).value
                Write-Result info "Web service AppID (web.config): '$serviceAppId' - its Allowed Machines must include this server's private IP / host name"
                if ($proxies) {
                    Write-Result info "TrustedProxies: $proxies - client Allowed Machines are checked against X-Forwarded-For from these"
                }
            }
        }
    }

    # --- Vault connectivity ----------------------------------------------------
    $vaultIni = Join-Path $ProviderPath 'Vault\Vault.ini'
    if (-not (Test-Path $vaultIni)) {
        Write-Result skip "Vault connectivity - $vaultIni not found" -Hint 'Use -ProviderPath if the Provider is installed elsewhere'
    } else {
        $ini       = Get-Content $vaultIni
        $addresses = (($ini | Where-Object { $_ -match '^\s*ADDRESS\s*=' }) -replace '^\s*ADDRESS\s*=\s*', '') -split ',' | ForEach-Object { $_.Trim() }
        $portLine  = ($ini | Where-Object { $_ -match '^\s*PORT\s*=' }) -replace '^\s*PORT\s*=\s*', ''
        $port      = if ($portLine) { [int]$portLine } else { 1858 }

        foreach ($vault in $addresses) {
            if (Test-TcpPort $vault $port) {
                Write-Result ok "Vault $($vault):$port is reachable"
            } else {
                Write-Result fail "Vault $($vault):$port is not reachable" -Hint 'Check the firewall / security group from this server to the Vault'
            }
        }
    }

    # --- Provider logs ---------------------------------------------------------
    # APPConsole.log has service errors; APPAudit.log has the reason each request failed (e.g. APPAP133E)
    foreach ($logName in 'APPConsole.log', 'APPAudit.log') {
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

# --- Test retrievals ---------------------------------------------------------
function Test-Retrieval {
    param([hashtable]$Target)

    # POST keeps the query parameters out of the URL (and out of IIS / proxy logs)
    $request = [ordered]@{ AppID = $Target.AppId; Safe = $Target.Safe; Object = $Target.Object
                           UserName = $Target.UserName; Address = $Target.Address; Reason = 'CCP health check' }
    foreach ($key in @($request.Keys)) { if (-not $request[$key]) { $request.Remove($key) } }
    $body = $request | ConvertTo-Json -Compress
    Write-Result info "Test retrieval: POST $url $body"

    try {
        $response = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body $body `
            -UseDefaultCredentials:$useWindowsAuth -TimeoutSec 30
        Write-Result ok "Retrieved account '$($response.UserName)' (Object: $($response.Name)) - password not displayed"
    } catch {
        $status = [int]$_.Exception.Response.StatusCode
        if ($status -eq 0) {
            Write-Result fail "Could not connect to $url - $($_.Exception.Message)" `
                -Hint 'Check the URL, and that the certificate matches the host name (Ccp.Url / -CcpUrl)'
            return
        }

        $code = ''; $message = $_.ErrorDetails.Message
        try {
            $ccpError = $message | ConvertFrom-Json
            $code = $ccpError.ErrorCode; $message = $ccpError.ErrorMsg
        } catch { }

        Write-Result fail "HTTP $status $code - $message" -Hint (Get-ErrorHint -Code $code -Status $status)
        if ($code -eq 'APPAP306E' -or $status -eq 403) {
            Write-Result info 'Note: a test from this server is checked against Allowed Machines too - run it from the application machine if this server is not allowed'
        }
    }
}

if ($AppId -or $Safe) {
    if (-not ($AppId -and $Safe -and ($Object -or $UserName -or $Address))) {
        Write-Result fail 'Test retrieval - specify -AppId, -Safe and the account (-Object, or -UserName and/or -Address)'
        return
    }
    $targets = @(@{ AppId = $AppId; Safe = $Safe; Object = $Object; UserName = $UserName; Address = $Address })
} elseif ($settings) {
    $targets = foreach ($s in $settings.Safes) {
        foreach ($a in $s.AppIds) {
            foreach ($acc in $s.Accounts) {
                @{ AppId = $a; Safe = $s.Name; Object = $acc.Name; UserName = $acc.UserName; Address = $acc.Address }
            }
        }
    }
} else {
    Write-Result skip "Test retrievals - no settings file ($ConfigPath) and no -AppId / -Safe given"
    return
}

foreach ($target in $targets) { Test-Retrieval $target }
