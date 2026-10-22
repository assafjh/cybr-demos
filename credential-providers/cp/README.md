# Credential Provider (CP)

Copy `settings.example.psd1` to `settings.psd1` and fill in the `<...>` values, then:

| Step | Runs | Does |
|---|---|---|
| `./1-Onboard.ps1` | Anywhere with access to the PVWA | Creates the application AppIDs with their authentication methods (Allowed Machines, OS user, path, hash), Safes, members and accounts - only what is missing. Prints a ready-to-use CP query |
| `./3-Test-Vault.ps1` | Anywhere with access to the PVWA | Checks the AppID, Safe, members and permissions, Provider users (incl. Audit Users) and the account's exact Object name |

`3-Test-Vault.ps1` is read-only and never displays passwords. Without parameters it checks
everything in the settings file; with parameters it checks one target:

```powershell
./3-Test-Vault.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01
```

## Things that commonly break a CP request

- **The Provider caches Applications.** After changing an AppID or its authentication methods,
  restart the Provider service (or wait for its cache refresh).
- **Every authentication method set on the AppID is checked.** A path or hash that matched the
  application yesterday stops matching after it is moved or rebuilt.
- **Object** is the account's Name in the Vault, not the username. Querying by `UserName` +
  `Address` avoids depending on it.
- **Privilege Cloud IP allowlist** - the public IP each CP machine connects from must be
  allowlisted for the Vault connection (port 1858). Machines behind one NAT share one entry.
