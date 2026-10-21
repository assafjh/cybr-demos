# Central Credential Provider

Demo and POC tooling for the CyberArk Central Credential Provider (CCP): Vault onboarding,
diagnostics, retrieval examples and lab setup.

> **Note:** These scripts are provided as examples for demos and POCs.
> They are not a supported product. Review and adapt before any production use.

All scripts run on Windows PowerShell 5.1 and PowerShell 7+ (Windows, macOS, Linux), against
PAM Self-Hosted or Privilege Cloud, using the Vault REST API directly - no modules to install.

## Layout

```
scripts/
  settings.example.psd1        Settings template - copy to settings.psd1
  common/CCP-Common.ps1        Shared helpers (settings, logon, REST calls, output)
  onboarding/                  Invoke-CCPOnboarding.ps1 - AppIDs, Safes, members, accounts
  diagnose/                    Test-CCPAccess.ps1 (Vault side), Test-CCPHealth.ps1 (CCP server)
  examples/                    How an application retrieves a password - REST (POST) and SOAP (legacy)
  lab/                         Lab setup: IIS prerequisites, self-signed HTTPS certificate
bruno/                         Bruno collection - REST and SOAP retrieval
```

## Settings

Every script reads `scripts/settings.psd1` by default. Copy `settings.example.psd1` to
`settings.psd1` and fill in the `<...>` values - the scripts stop and list any value left unfilled.
For another environment, create e.g. `settings-customer.psd1` and pass `-ConfigPath`.

`settings.psd1` and `settings-*.psd1` are git-ignored: they hold tenant names and addresses.
No passwords are stored. The logon secret is asked once per PowerShell window and kept in memory
only (`-NewCredential` asks again).

Privilege Cloud logon uses an Identity **service user** (OAuth client credentials) - an
interactive user with MFA will not work.

## Onboarding

```powershell
cd scripts/onboarding
./Invoke-CCPOnboarding.ps1
```

Creates what is missing and reports what already exists - safe to re-run:

- **Applications** - `AIMWebService` (the CCP web service itself) and the client AppID, with
  their Allowed Machines.
- **Safes** - created without a managing CPM, with the human owners (`SafeOwners`), the AppIDs
  (Retrieve + List) and the Provider users (Retrieve + List + View Safe Members) as members.
- **Accounts** - matched by UserName + Address, so accounts created manually in the PVWA are
  found. The actual Object name is read back and printed as a ready-to-use CCP request.

It never deletes and never overwrites passwords or permissions; missing permissions on
existing members are reported as warnings.

## Diagnostics

| Script | Runs | Checks |
|---|---|---|
| `Test-CCPAccess.ps1` | Anywhere with access to the PVWA | AppID and its authentication methods, Safe, members and permissions, Provider users (incl. Audit Users), the account and its exact Object name |
| `Test-CCPHealth.ps1` | On the CCP server | Provider service, IIS and AIMWebService, connectivity to the Vault, errors in `APPConsole.log` / `APPAudit.log`, test retrievals with the CCP error code explained |

Both are read-only and never display passwords. Tested against Privilege Cloud; the PAM
Self-Hosted logon (`/API/auth/<type>/Logon`) is not tested yet. Without parameters they check everything in
the settings file; with parameters they check one target - e.g. a Safe the customer set up:

```powershell
./Test-CCPAccess.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01
```

## Things that commonly break a CCP request

- **Two kinds of AppID.** The CCP web service authenticates itself to the Provider with its own
  AppID - `<add key="AppID">` in its `web.config`, `AIMWebService` by default. It is not a member
  of any Safe; its Allowed Machines are the CCP servers. Every client application gets its own
  AppID, with its own Allowed Machines and Safe memberships.
- **`AIMWebService` Allowed Machines** must hold the address the CCP server knows itself by -
  its private IP or host name, not a public / Elastic IP in front of it (APPAP307E + APPAP133E
  in `APPAudit.log`).
- **The Provider caches Applications.** After changing an AppID or its Allowed Machines,
  restart the Provider service (or wait for its cache refresh).
- **Client Allowed Machines** is the address the CCP sees. Behind a load balancer that is the
  LB address, unless `TrustedProxies` is set in the CCP `web.config`.
- **Object** is the account's Name in the Vault, not the username. Querying by `UserName` +
  `Address` avoids depending on it.
- **Privilege Cloud IP allowlist** - the CCP server's public IP must be allowlisted for the
  Vault connection (port 1858).

## Retrieval examples

```powershell
cd scripts/examples
./Get-CCPPassword-REST.ps1
./Get-CCPPassword-SOAP.ps1
```

They take the CCP URL, AppID, Safe and account from the settings file (the first Safe with an
AppID) and query by UserName + Address. Run them from the machine in the client AppID's
Allowed Machines.

## Lab setup

On the CCP server, as administrator:

```powershell
./scripts/lab/Install-CCPLabPrerequisites.ps1   # IIS features, .NET version
./scripts/lab/New-CCPLabCertificate.ps1         # Self-signed HTTPS certificate on 443
```

Edit the host names in `New-CCPLabCertificate.ps1` first. A client on another machine must
trust the certificate (import it to its trusted root store).
