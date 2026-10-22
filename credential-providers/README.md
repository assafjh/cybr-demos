# Credential Providers

Demo and POC tooling for the CyberArk Credential Provider (CP) and Central Credential Provider
(CCP), against PAM Self-Hosted or Privilege Cloud.

> **Note:** These scripts are provided as examples for demos and POCs.
> They are not a supported product. Review and adapt before any production use.

## Pick your product

| Folder | For | Steps |
|---|---|---|
| [`ccp/`](ccp/) | Central Credential Provider - applications call a web service | `1-Onboard` → `2-Test-Vault` → `3-Test-Server` |
| [`cp/`](cp/) | Credential Provider - an agent on the application machine | `1-Onboard` → `3-Test-Vault` |

In the folder: copy `settings.example.psd1` to `settings.psd1`, fill in the `<...>` values, and run
the numbered scripts in order. Every script is safe to re-run. `common/` holds the code both
products share - you don't run anything there.

All scripts run on Windows PowerShell 5.1 and PowerShell 7+ (Windows, macOS, Linux), using the
Vault REST API directly - no modules to install.

## Settings

`settings.psd1` and `settings-*.psd1` are git-ignored: they hold tenant names and addresses.
No passwords are stored. The logon secret is asked once per PowerShell window and kept in memory
only (`-NewCredential` asks again). For another environment, create e.g. `settings-customer.psd1`
and pass `-ConfigPath`.

Privilege Cloud logon uses an Identity **service user** (OAuth client credentials) - an
interactive user with MFA will not work.

## Copied as a zip?

Windows marks downloaded scripts and the execution policy blocks them - unblock the folder once
(a `git clone` is not marked):
```powershell
Get-ChildItem .\credential-providers -Recurse -Include *.ps1, *.psd1 | Unblock-File
```
