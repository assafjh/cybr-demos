# Credential Provider (CP)

Copy `settings.example.psd1` to `settings.psd1` and fill in the `<...>` values, then:

On a Linux CP machine the machine-side scripts are bash: copy `1-preflight.sh`, `4-test-server.sh` and
`settings.conf.example` (as `settings.conf`) to it - they need nothing else.

| Step | Runs | Does |
|---|---|---|
| `./1-Preflight.ps1` (Windows)<br>`./1-preflight.sh` (Linux) | On the CP machine | Checks the Vault address, DNS, port, the public IP for the Privilege Cloud allowlist and disk space, then prints what to enter in the installation |
| *Install the CP* | On the CP machine, as administrator / root | Windows: run `setup.exe` from the package, then restart. Linux: the steps `1-preflight.sh` prints (Vault.ini, credential file, aimparms, rpm / dpkg) |
| `./2-Onboard.ps1` | Anywhere with access to the PVWA | Creates the application AppIDs with their authentication methods (Allowed Machines, OS user, path, hash), Safes, members - incl. the Provider user - and accounts. Prints a ready-to-use CP query |
| `./3-Test-Vault.ps1` | Anywhere with access to the PVWA | Checks the AppID, Safe, members and permissions, Provider users (incl. Audit Users) and the account's exact Object name |
| `./4-Test-Server.ps1` (Windows)<br>`./4-test-server.sh` (Linux, as root) | On the CP machine | Checks the Provider service, connectivity to the Vault, errors in the Provider logs, and test retrievals through CLIPasswordSDK with the error code explained |

Install before onboarding: the Provider user only exists after the installation, and `2-Onboard`
adds it to the Safes. Put its name (`Prov_<host name>` by default) in `Providers` in the settings file.

The test scripts are read-only and never display passwords. Without parameters they check
everything in the settings file; with parameters they check one target:

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
  An open port is not enough: the Vault rejects a non-allowlisted IP after the connection opens.
- **The Vault address is a host name** - `vault-<subdomain>.privilegecloud.cyberark.cloud`, not the
  portal URL. The installer crashes without a message on a URL or a typo; `1-Preflight` checks it first.
