# Filename: Provider-Common.ps1
# Shared helpers for the CP and CCP scripts: settings file, Vault logon/logoff, REST calls and console output.
# Dot-source it from a product script:  . (Join-Path $PSScriptRoot '../common/Provider-Common.ps1')
# Works on Windows PowerShell 5.1 and PowerShell 7+.

# Windows PowerShell 5.1 does not use TLS 1.2 by default
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Import-ProviderSettings {
    # Loads the settings file and fails early on placeholders (<...>) left in the required sections.
    param(
        [Parameter(Mandatory)] [string]$Path,
        [string[]]$Required,    # Top-level sections the calling script needs, e.g. 'Connection', 'Safes'
        [string[]]$Optional # Sections checked for placeholders only when present
    )

    if (-not (Test-Path $Path)) {
        throw "Settings file not found: $Path - copy settings.example.psd1 to settings.psd1 and fill it in"
    }
    $settings = Import-PowerShellDataFile -Path $Path

    # Drop the fields that do not apply to the chosen connection type, so their placeholders don't count
    if ($settings.Connection.Type -eq 'SelfHosted')     { $settings.Connection.Remove('IdentityUrl') }
    if ($settings.Connection.Type -eq 'PrivilegeCloud') { $settings.Connection.Remove('AuthType') }

    function Find-Placeholder($Value, [string]$Name) {
        if ($Value -is [string] -and $Value -match '<[^<>]+>') { $Name }
        elseif ($Value -is [hashtable]) { foreach ($key in $Value.Keys) { Find-Placeholder $Value[$key] "$Name.$key" } }
        elseif ($Value -is [array]) { for ($i = 0; $i -lt $Value.Count; $i++) { Find-Placeholder $Value[$i] "$Name[$i]" } }
    }

    foreach ($section in $Required) {
        if (-not $settings.ContainsKey($section)) { throw "Settings file $Path has no '$section' section" }
    }
    $present = @($Required) + @(foreach ($section in $Optional) { if ($settings.ContainsKey($section)) { $section } })
    $unfilled = foreach ($section in $present) { Find-Placeholder $settings[$section] $section }
    if ($unfilled) { throw "Fill in these settings in ${Path}: $($unfilled -join ', ')" }

    $settings
}

function Get-TestTargets {
    # What a test script checks: the AppID + Safe + account given as parameters, or else every
    # AppID + account combination in the settings file.
    param([hashtable]$Settings, [string]$AppId, [string]$Safe, [string]$Object, [string]$UserName, [string]$Address)

    if ($AppId -or $Safe) {
        if (-not ($AppId -and $Safe -and ($Object -or $UserName -or $Address))) {
            throw 'Specify -AppId, -Safe and the account (-Object, or -UserName and/or -Address)'
        }
        return @(@{ AppId = $AppId; Safe = $Safe; Object = $Object; UserName = $UserName; Address = $Address })
    }

    foreach ($s in $Settings.Safes) {
        foreach ($a in $s.AppIds) {
            foreach ($acc in $s.Accounts) {
                @{ AppId = $a; Safe = $s.Name; Object = $acc.Name; UserName = $acc.UserName; Address = $acc.Address }
            }
        }
    }
}

function Connect-Vault {
    # Logs on to PAM Self-Hosted (PVWA) or Privilege Cloud and returns a session for Invoke-VaultApi.
    # The credential is asked once per PowerShell session and kept in memory only (per PvwaUrl),
    # so the next script in the same window logs on without asking again.
    param(
        [Parameter(Mandatory)] [hashtable]$Connection,
        [pscredential]$Credential,
        [switch]$NewCredential    # Ask again instead of using the remembered credential
    )

    $baseUrl  = "$($Connection.PvwaUrl.TrimEnd('/'))/PasswordVault"
    $cacheKey = $Connection.PvwaUrl.TrimEnd('/').ToLower()
    if (-not $global:VaultCredentialCache) { $global:VaultCredentialCache = @{} }
    if ($NewCredential) { $global:VaultCredentialCache.Remove($cacheKey) }

    $needsCredential = -not ($Connection.Type -eq 'SelfHosted' -and $Connection.AuthType -eq 'Windows')
    if ($needsCredential -and -not $Credential) {
        $Credential = $global:VaultCredentialCache[$cacheKey]
        if (-not $Credential) {
            $message = if ($Connection.Type -eq 'PrivilegeCloud') { 'Identity service user (client ID / client secret)' } else { "Vault user ($($Connection.AuthType))" }
            $Credential = if ($Connection.UserName) { Get-Credential -UserName $Connection.UserName -Message $message } else { Get-Credential -Message $message }
        }
    }

    try {
        switch ($Connection.Type) {
            'SelfHosted' {
                $logonUrl = "$baseUrl/API/auth/$($Connection.AuthType)/Logon"
                if ($Connection.AuthType -eq 'Windows') {
                    $authorization = Invoke-RestMethod -Method Post -Uri $logonUrl -UseDefaultCredentials -ContentType 'application/json' -Body '{}'
                } else {
                    $body = @{ username = $Credential.UserName; password = $Credential.GetNetworkCredential().Password } | ConvertTo-Json
                    $authorization = Invoke-RestMethod -Method Post -Uri $logonUrl -ContentType 'application/json' -Body $body
                }
            }
            'PrivilegeCloud' {
                $body = @{
                    grant_type    = 'client_credentials'
                    client_id     = $Credential.UserName
                    client_secret = $Credential.GetNetworkCredential().Password
                }
                $response = Invoke-RestMethod -Method Post -Uri "$($Connection.IdentityUrl.TrimEnd('/'))/oauth2/platformtoken" `
                    -ContentType 'application/x-www-form-urlencoded' -Body $body
                $authorization = "Bearer $($response.access_token)"
            }
            default { throw "Connection.Type must be 'SelfHosted' or 'PrivilegeCloud' (got '$($Connection.Type)')" }
        }
    } catch {
        # A failed logon must not leave a wrong credential behind
        $global:VaultCredentialCache.Remove($cacheKey)
        $detail = $_.Exception.Message
        try {
            # Vault errors: ErrorCode / ErrorMessage. Identity OAuth errors: error / error_description
            $logonError = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($logonError.ErrorCode) { $detail = "$($logonError.ErrorCode): $($logonError.ErrorMessage)" }
            elseif ($logonError.error) { $detail = "$($logonError.error): $($logonError.error_description)" }
        } catch { }
        throw "Logon to $($Connection.PvwaUrl) failed - $detail"
    }

    if ($needsCredential) { $global:VaultCredentialCache[$cacheKey] = $Credential }
    @{ Type = $Connection.Type; BaseUrl = $baseUrl; Headers = @{ Authorization = $authorization } }
}

function Disconnect-Vault {
    # Privilege Cloud tokens simply expire; Self-Hosted sessions should be closed.
    param([Parameter(Mandatory)] [hashtable]$Session)

    if ($Session.Type -eq 'SelfHosted') {
        try { Invoke-VaultApi -Session $Session -Method Post -Path '/API/auth/Logoff' | Out-Null } catch { }
    }
}

function Invoke-VaultApi {
    # Calls the Vault REST API. Path is relative to /PasswordVault, e.g. '/API/Safes'.
    # Fails with the Vault's ErrorCode/ErrorMessage, or returns $null on 404 when -AllowNotFound is set.
    param(
        [Parameter(Mandatory)] [hashtable]$Session,
        [Parameter(Mandatory)] [string]$Method,
        [Parameter(Mandatory)] [string]$Path,
        [object]$Body,
        [switch]$AllowNotFound
    )

    $request = @{
        Method      = $Method
        Uri         = "$($Session.BaseUrl)$Path"
        Headers     = $Session.Headers
        ContentType = 'application/json'
    }
    if ($null -ne $Body) { $request.Body = $Body | ConvertTo-Json -Depth 10 }

    try {
        Invoke-RestMethod @request
    } catch {
        $status = [int]$_.Exception.Response.StatusCode
        if ($AllowNotFound -and $status -eq 404) { return $null }

        $detail = $_.ErrorDetails.Message
        try {
            $vaultError = $detail | ConvertFrom-Json
            $detail = "$($vaultError.ErrorCode): $($vaultError.ErrorMessage)"
        } catch { }
        if (-not $detail) { $detail = $_.Exception.Message }

        # StatusCode is kept on the exception so callers can react to e.g. 403 (no permission)
        $exception = [Exception]::new("$Method $Path failed (HTTP $status) - $detail")
        $exception.Data['StatusCode'] = $status
        throw $exception
    }
}

function Write-Result {
    # One line per item: [status] message
    param(
        [Parameter(Mandatory)] [ValidateSet('exists', 'created', 'added', 'ok', 'fail', 'skip', 'warn', 'info')] [string]$Status,
        [Parameter(Mandatory)] [string]$Message,
        [string]$Hint    # What to do about it - printed on its own line
    )

    $color = @{
        exists = 'Gray'; created = 'Green'; added = 'Green'; ok = 'Green'
        fail = 'Red'; skip = 'DarkYellow'; warn = 'Yellow'; info = 'Cyan'
    }[$Status]

    Write-Host ('{0,-10} {1}' -f "[$Status]", $Message) -ForegroundColor $color
    if ($Hint) { Write-Host ('{0,-10} -> {1}' -f '', $Hint) -ForegroundColor $color }
}
function Get-CCPRequestOptions {
    # Extra parameters for requests to the CCP. -SkipCertificateCheck is for a lab with a
    # self-signed certificate only - it accepts any certificate the server presents.
    param([switch]$SkipCertificateCheck)

    $options = @{}
    if ($SkipCertificateCheck) {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $options.SkipCertificateCheck = $true
        } else {
            [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }
    }
    $options
}
