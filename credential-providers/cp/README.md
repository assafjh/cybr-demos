# Credential Provider (CP)

Copy `settings.example.psd1` to `settings.psd1` and fill in the `<...>` values, then:

On a Linux CP machine the machine-side scripts are bash: copy `1-preflight.sh`, `4-test-server.sh` and
`settings.conf.example` (as `settings.conf`) to it - they need nothing else.

| Step | Runs | Does |
|---|---|---|
| `./1-Preflight.ps1` (Windows)<br>`./1-preflight.sh` (Linux) | On the CP machine | Checks the Vault address, DNS, port, the public IP for the Privilege Cloud allowlist and disk space, then prints what to enter in the installation |
| *Install the CP* | On the CP machine, as administrator / root | Windows: run `setup.exe` from the package, then restart. Linux: the steps `1-preflight.sh` prints - install the package, then register the Provider with `createenv` |
| `./2-Onboard.ps1` | Anywhere with access to the PVWA | Creates the application AppIDs with their authentication methods (Allowed Machines, OS user, path, hash), Safes, members - incl. the Provider user - and accounts. Prints a ready-to-use CP query |
| `./3-Test-Vault.ps1` | Anywhere with access to the PVWA | Checks the AppID, Safe, members and permissions, Provider users (incl. Audit Users) and the account's exact Object name |
| `./4-Test-Server.ps1` (Windows)<br>`./4-test-server.sh` (Linux, as root) | On the CP machine | Checks the Provider service, connectivity to the Vault, errors in the Provider logs, and test retrievals through CLIPasswordSDK with the error code explained |

Install before onboarding: the Provider user only exists after the installation, and `2-Onboard`
adds it to the Safes. Put its name in `Providers` in the settings file, and the CP machine's private
IP in the AppID's `AllowedMachines`. After onboarding, restart the Provider service - it caches
Applications and Safe permissions.

`2-Onboard` prints the commands for the next steps: the Provider restart (when an AppID or Safe
member changed - the Provider caches them) and the test command for each CP machine, with the AppID
and account filled in:

```
Windows: .\4-Test-Server.ps1 -AppId 'MyApp' -Safe 'App-Safe' -UserName 'svc_db' -Address 'db01'
Linux:   sudo ./4-test-server.sh 'MyApp' 'App-Safe' 'svc_db' 'db01'
```

The test scripts are read-only and never display passwords. `3-Test-Vault.ps1` without parameters
checks everything in the settings file; with `-AppId`, `-Safe` and an account it checks one target.

## Things that commonly break a CP request

- **The Provider caches Applications and Safe permissions.** After changing an AppID, its
  authentication methods or Safe members, restart the Provider service (or wait for its cache refresh).
- **Allowed Machines is the machine's own address** - its private IP, not the public / Elastic IP.
  On a rejection, APPAudit.log (APPAP133E) lists every address the Provider sent.
- **Every authentication method set on the AppID is checked.** A path or hash that matched the
  application yesterday stops matching after it is moved or rebuilt.
- **Object** is the account's Name in the Vault, not the username. Querying by `UserName` +
  `Address` avoids depending on it.
- **Privilege Cloud IP allowlist** - the public IP each CP machine connects from must be
  allowlisted for the Vault connection (port 1858). Machines behind one NAT share one entry.
  A machine that is not allowlisted cannot open the connection at all - `1-Preflight` prints its public IP.
- **Provider user names are at most 28 characters.** On Linux the installer names it
  `Prov_<full host name>` - on AWS that is too long, and it fails with "User ... has not been
  defined" while still reporting success. `1-preflight.sh` has you register it with `createenv`
  and a name you choose.
- **`HardenFSPermissions=yes`** (the Linux installer default) leaves the SDK folder root-only, so
  applications running as another OS user cannot retrieve. `4-test-server.sh` checks it and
  retrieves as the application's OS user (`APP_OS_USER`), not as root.
- **The Vault address is a host name** - `vault-<subdomain>.privilegecloud.cyberark.cloud`, not the
  portal URL. The installer crashes without a message on a URL or a typo; `1-Preflight` checks it first.
