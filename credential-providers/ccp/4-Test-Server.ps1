# Filename: 4-Test-Server.ps1
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
# For the Vault side (AppID, Safe members, Object name) use 3-Test-Vault.ps1.
#
# Examples:
#   ./4-Test-Server.ps1
#   ./4-Test-Server.ps1 -CcpUrl https://localhost
#   ./4-Test-Server.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'settings.psd1'),
    [string]$CcpUrl,                  # Overrides Ccp.Url - the host name must match the CCP certificate
    [string]$WebServiceName,          # Overrides Ccp.WebServiceName
    [string]$ProviderPath,

    # One test retrieval instead of the ones in the settings file
    [string]$AppId,
    [string]$Safe,
    [string]$Object,
    [string]$UserName,
    [string]$Address,
    [switch]$UseDefaultCredentials,    # When the CCP uses Windows
    [switch]$SkipCertificateCheck
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/Provider-Common.ps1')
. (Join-Path $PSScriptRoot '../common/ProviderHost.ps1')

function Get-ErrorHint {
    param([string]$Code, [int]$Status)
    $hint = Get-ProviderErrorHint $Code
    if ($hint) { return $hint }
    switch ($Status) {
        401     { 'Authentication required - the CCP may use Windows Authentication (-UseDefaultCredentials) or a client certificate' }
        403     { 'Forbidden - check the AppID authentication methods (Allowed Machines, OS user, certificate)' }
        404     { 'Not found - check the web service name, or run 3-Test-Vault.ps1' }
        default { 'Look up the error code in the CyberArk Credential Providers documentation' }
    }
}

# --- Settings: CCP URL, web service name, test retrievals ----------------------
$settings = $null
if (Test-Path $ConfigPath) {
    try {
        $settings = Import-ProviderSettings -Path $ConfigPath -Required Ccp
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
$options = Get-CCPRequestOptions -SkipCertificateCheck:($SkipCertificateCheck -or $settings.Ccp.SkipCertificateCheck -eq $true)

Write-Host 'Read-only: this script changes nothing and never displays passwords' -ForegroundColor Cyan
Write-Host ''

$onWindows = [Environment]::OSVersion.Platform -eq 'Win32NT'

# --- Provider service --------------------------------------------------------
if (-not $onWindows) {
    Write-Result skip 'Machine checks (service, IIS, Vault.ini, log) - not running on Windows'
} else {
    Test-ProviderService

    # --- IIS and the web service ---------------------------------------------
    # appcmd instead of the WebAdministration module, which is not fully usable from PowerShell 7
    $appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
    $w3svc = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
    if (-not $w3svc -or $w3svc.Status -ne 'Running') {
        Write-Result fail 'IIS (W3SVC) is not running' -Hint 'Start it: Start-Service W3SVC'
    } elseif (-not (Test-Path $appcmd)) {
        Write-Result skip "IIS application check - $appcmd not found"
    } else {
        $webApp = ([xml](& $appcmd list app /path:/$serviceName /xml)).appcmd.APP | Select-Object -First 1
        if (-not $webApp) {
            Write-Result fail "IIS application '/$serviceName' not found" -Hint 'Check the web service name (Ccp.WebServiceName / -WebServiceName) or the CCP installation'
        } else {
            $poolName = $webApp.'APPPOOL.NAME'
            $poolState = ([xml](& $appcmd list apppool /apppool.name:$poolName /xml)).appcmd.APPPOOL.state
            if ($poolState -ne 'Started') {
                Write-Result fail "IIS application '$($webApp.'APP.NAME')' - application pool '$poolName' is $poolState" -Hint "Start it: & `"$appcmd`" start apppool /apppool.name:`"$poolName`""
            } else {
                Write-Result ok "IIS application '$($webApp.'APP.NAME')' - application pool '$poolName' started"
            }

            # The AppID the web service itself uses, and whether it trusts a load balancer's X-Forwarded-For
            $vdir = ([xml](& $appcmd list vdir /app.name:$($webApp.'APP.NAME') /xml)).appcmd.VDIR | Select-Object -First 1
            $webConfig = Join-Path ([Environment]::ExpandEnvironmentVariables($vdir.physicalPath)) 'web.config'
            if (Test-Path $webConfig) {
                $appSettings = ([xml](Get-Content $webConfig -Raw)).configuration.appSettings.add
                $serviceAppId = ($appSettings | Where-Object { $_.key -eq 'AppID' }).value
                $proxies = ($appSettings | Where-Object { $_.key -eq 'TrustedProxies' }).value
                Write-Result info "Web service AppID (web.config): '$serviceAppId' - its Allowed Machines must include this server's private IP / host name"
                if ($proxies) {
                    Write-Result info "TrustedProxies: $proxies - client Allowed Machines are checked against X-Forwarded-For from these"
                }
            }
            
            # Hardened IIS images (CIS baselines) break the web service in ways that look like a broken install
            $appPath = $webApp.'APP.NAME'

            $trust = ([xml](& $appcmd list config $appPath /section:system.web/trust | Out-String)).'system.web'.trust.level
            if ($trust -and $trust -ne 'Full') {
                Write-Result fail ".NET trust level is '$trust'" -Hint 'The web service needs Full trust (<trust level="Full" />). If the section is locked in machine.config, unlock it there - overriding a locked section gives HTTP 500.19'
            } else {
                Write-Result ok '.NET trust level: Full'
            }
            
            $filtering = ([xml](& $appcmd list config $appPath /section:system.webServer/security/requestFiltering | Out-String)).'system.webServer'.security.requestFiltering
            if ($filtering.fileExtensions.allowUnlisted -eq 'false') {
                Write-Result fail 'Request filtering blocks unlisted file name extensions - requests return HTTP 404.7' -Hint 'Allow unlisted file name extensions for this application only (IIS Manager > Request Filtering > Edit Feature Settings)'
            } else {
                Write-Result ok 'Request filtering allows the web service requests'
            }

            # Windows Server 2022+: client certificate authentication does not work over TLS 1.3 (IIS requests
            # the certificate after the handshake). The connection is reset - there is no HTTP error to see.
            $sslFlags = ([xml](& $appcmd list config $appPath /section:system.webServer/security/access | Out-String)).'system.webServer'.security.access.sslFlags
            if ([Environment]::OSVersion.Version.Build -ge 20348 -and $sslFlags -match 'SslRequireCert|SslNegotiateCert') {
                Write-Result info "Client certificates are used ($sslFlags) on Windows Server 2022+ - over TLS 1.3 the connection is reset ('Request Cancelled' in the IIS log)" -Hint 'If client certificate requests fail, disable TLS 1.3 over TCP and HTTP/2 on the HTTPS binding (IIS Manager > Site Bindings)'
            }
        }
    }

    # --- Provider install folder, Vault connectivity, logs -------------------------
    if (-not $ProviderPath) { $ProviderPath = Find-ProviderPath }
    Test-ProviderInstall -ProviderPath $ProviderPath
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
            -UseDefaultCredentials:$useWindowsAuth -TimeoutSec 30 @options
        Write-Result ok "Retrieved account '$($response.UserName)@$($response.Address)' - password not displayed"
    } catch {
        $status = [int]$_.Exception.Response.StatusCode
        if ($status -eq 0) {
            Write-Result fail "Could not connect to $url - $($_.Exception.Message)" `
                -Hint 'Check the URL, and that the certificate matches the host name (Ccp.Url / -CcpUrl). On the CCP server itself: -CcpUrl https://localhost'
            return
        }

        $code = ''; $message = $_.ErrorDetails.Message
        try {
            $ccpError = $message | ConvertFrom-Json
            $code = $ccpError.ErrorCode; $message = $ccpError.ErrorMsg
        } catch { }

        Write-Result fail "HTTP $status $code - $message" -Hint (Get-ErrorHint -Code $code -Status $status)

        # On the CCP server the Provider log has the actual reason - show the latest entry
        Write-LastAuditError -ProviderPath $ProviderPath -Code $code

        if ($code -in 'APPAP306E', 'APPEX003E' -or $status -eq 403) {
            Write-Result info 'Note: Allowed Machines is checked for this request too - from the CCP server itself the CCP sees ::1 / 127.0.0.1. Run it from the application machine, or allow this server in a health-check AppID that only has a dummy Safe'
        }
    }
}

if (-not ($AppId -or $Safe -or $settings)) {
    Write-Result skip "Test retrievals - no settings file ($ConfigPath) and no -AppId / -Safe given"
    return
}
try {
    $targets = Get-TestTargets -Settings $settings -AppId $AppId -Safe $Safe -Object $Object -UserName $UserName -Address $Address
} catch {
    Write-Result fail "Test retrieval - $($_.Exception.Message)"
    return
}

foreach ($target in $targets) { Test-Retrieval $target }
