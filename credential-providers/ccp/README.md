# Central Credential Provider (CCP)

Copy `settings.example.psd1` to `settings.psd1` and fill in the `<...>` values, then:

| Step | Runs | Does |
|---|---|---|
| `./1-Onboard.ps1` | Anywhere with access to the PVWA | Creates the `AIMWebService` and client AppIDs, Safes, members and accounts - only what is missing. Prints a ready-to-use CCP request |
| `./2-Test-Vault.ps1` | Anywhere with access to the PVWA | Checks the AppID, Safe, members and permissions, Provider users (incl. Audit Users) and the account's exact Object name |
| `./3-Test-Server.ps1` | On the CCP server, as administrator | Checks the Provider service, IIS and AIMWebService, hardened-IIS settings, connectivity to the Vault, errors in the Provider logs, and test retrievals with the CCP error code explained |

The test scripts are read-only and never display passwords. Without parameters they check
everything in the settings file; with parameters they check one target - e.g. a Safe the
customer set up:

```powershell
./2-Test-Vault.ps1 -AppId MyApp -Safe App-Safe -UserName svc_db -Address db01
```

## Retrieval examples

`examples/Get-Password-REST.ps1` and `examples/Get-Password-SOAP.ps1` show how an application
retrieves a password. They take the CCP URL, AppID, Safe and account from the settings file and
query by UserName + Address. Run them from a machine in the client AppID's Allowed Machines.
`bruno/` has the same requests as a Bruno collection.

## Lab

`lab/Prepare-Lab.ps1` installs the IIS features and binds a self-signed HTTPS certificate -
run it on a lab server before installing the CCP. A client on another machine must trust the
certificate (import it to its trusted root store).

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
- **Privilege Cloud IP allowlist** - the public IP the CCP server connects from must be
  allowlisted for the Vault connection (port 1858).
