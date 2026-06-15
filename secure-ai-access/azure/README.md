# CyberArk Secure AI Agents — Azure Scanner Deployment Toolkit

A small set of helper scripts that wrap the vendor's `deploy.sh` for the CyberArk
Secure AI Agents Azure scanner. They make a deployment **repeatable, validated,
and safe** without modifying any vendor file.

The vendor installer works, but a real deployment tends to fail on the
*environment* (subscription selection, Conditional Access, RBAC, resource-provider
registration, region/SKU availability, global name collisions) rather than the
script itself. This toolkit checks all of that up front, drives the deploy from a
single config file, and gives you a clean uninstall and a post-deploy status check.

> Nothing here modifies the vendor's `deploy.sh`, `main.bicep`, or the function zip.
> You can drop in vendor updates freely.

Fix Permission - Access management for Azure resources
https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Properties

Git Bash AZ Cert error:
export AZURE_CLI_DISABLE_CONNECTION_VERIFICATION=1

---

## Contents

| File | What it does |
|------|--------------|
| `scanner.conf` | Single source of truth: subscription ID + all resource names. Every script reads this. |
| `preflight.sh` | Read-only checks that everything the deploy needs is in place. `--validate` adds a real `what-if` dry-run. |
| `run-deploy.sh` | Thin wrapper that pre-fills the **unmodified** vendor `deploy.sh` prompts from `scanner.conf`. |
| `discover.sh` | Read-only sweep of **all** subscriptions to find leftover scanner resources; prints ready-to-run cleanup commands. |
| `uninstall.sh` | Guarded uninstaller (dry-run by default, typed confirmation, KV soft-delete handling). |
| `status.sh` | Post-deploy health + scan-run status (read-only; `--run` to trigger a scan). |

You also need the vendor package in the same folder: `deploy.sh`, `main.bicep`,
and the function code zip (e.g. `cyberarkscanner-fa.zip`).

---

## Prerequisites

- **Azure CLI** (`az`). Install: `winget install -e --id Microsoft.AzureCLI` (Windows) or https://aka.ms/installazurecliwindows.
- **A bash shell.** On Windows use **Git Bash** (`winget install -e --id Git.Git`) — the vendor script is bash, PowerShell cannot run it. WSL or Cloud Shell also work.
- **Permissions on the target subscription**: `Owner` (or `Contributor` + `User Access Administrator`). The bicep creates role assignments on the storage account, which `Contributor` alone cannot do.
- **Entra**: an account that can grant admin consent (`Global Administrator` or `Privileged Role Administrator`) — the deploy registers an app and consents to `Application.Read.All`.
- Run from a context that satisfies the tenant's **Conditional Access** (a managed/compliant device often works where Cloud Shell is blocked).

---

## Configuration

Copy the template and fill it in once:

```bash
cp scanner.conf.example scanner.conf
```

```ini
SUBSCRIPTION_ID="<GUID>"          # ALWAYS the ID, never the display name (names can collide)
LOCATION="<region>"               # must support Flex Consumption (see preflight)
NAME_PREFIX="cyberarkscanner"     # used by discover.sh to sweep for drifted leftover names
RESOURCE_GROUP="<rg-name>"
FUNCTION_APP="<func-name>"        # GLOBAL namespace, must be unique
STORAGE_ACCOUNT="<sa-name>"       # GLOBAL: 3-24 chars, lowercase a-z0-9, NO hyphens
KEY_VAULT="<kv-name>"             # GLOBAL: 3-24, start with a letter, no consecutive hyphens
APP_INSIGHTS="<ai-name>"
APP_REGISTRATION="<app-reg-name>"
```

Naming rules are enforced by `preflight.sh`. The three "GLOBAL" resources must be
unique across all of Azure, so a name taken (or soft-deleted) elsewhere will fail.

**Minimum you must set:** `SUBSCRIPTION_ID` plus the three globally-unique names
(`FUNCTION_APP`, `STORAGE_ACCOUNT`, `KEY_VAULT`). The rest have safe defaults.

**Region:** `LOCATION` is honored even though the vendor script hardcodes its own —
`run-deploy.sh` pre-creates the RG in `LOCATION` first (the vendor's `az group
create` then no-ops, since RG location is immutable). On re-runs, `preflight.sh`
derives the effective region from the existing RG. It is **not** auto-picked,
because for a customer tenant the region is a data-residency decision.

---

## Procedure

```
cleanup  ->  preflight  ->  preflight --validate  ->  (CyberArk Identity)  ->  run-deploy  ->  status
```

### 0. Prep (once)
Put the toolkit + vendor package in one folder, then create and edit `scanner.conf`.

### 1. Cleanup (only if a previous attempt left resources)
Sweep every subscription you can see for leftovers, then remove them. Resource
names come from `scanner.conf`.

```bash
bash discover.sh
```

`discover.sh` is read-only. It reports where the resource group, any stray
function app, soft-deleted Key Vaults, and the tenant-level app registration
live — and prints the exact `uninstall.sh` commands for each subscription that
holds the RG. Run those — **dry-run first** (no `--yes`), eyeball the plan, then
execute:

```bash
bash uninstall.sh --subscription <SUB_ID> --rg <RESOURCE_GROUP>                       # dry-run
bash uninstall.sh --subscription <SUB_ID> --rg <RESOURCE_GROUP> \
                  --app-name <APP_REGISTRATION> --purge-kv --yes                      # execute
```

`--purge-kv` frees the Key Vault's (global) name immediately instead of leaving it
soft-deleted (~90 days), so a redeploy with the same name won't collide.

### 2. Preflight
```bash
bash preflight.sh
```
Checks tooling, sign-in, **subscription (by ID, no guessing)**, Conditional Access
tokens for all three audiences (ARM / Graph / App Service-Kudu), RBAC, Entra admin
rights, resource-provider registration, **Flex Consumption region availability**,
global name availability, and required files. Fix every `[FAIL]` using its `fix:` hint.

### 3. Validate (real dry-run)
```bash
bash preflight.sh --validate
```
Runs `az deployment group what-if` against the real bicep. This is the only step
that surfaces **Azure Policy / deny assignments, quota limits, and template errors**
— without creating anything. A clean preview means ARM should accept the deploy.
(`what-if` is RG-scoped; if the RG doesn't exist yet it offers to create an empty one.)

### 4. CyberArk Identity (manual prerequisite)
In CyberArk Identity Administration: create a service user (Is OAuth confidential
client + Is Service User) and add it to the role **"Discovery & Context Azure
Communication"**. Have its tenant subdomain, username, and password ready. Without
this, the deploy succeeds but the scan has nothing to authenticate with.

### 5. Deploy
```bash
bash run-deploy.sh
```
Selects the subscription, pre-fills every name prompt from `scanner.conf`, reads the
service-user credentials (password hidden), and hands off to the **unmodified**
vendor `deploy.sh`. Success at the end shows **HTTP 202** (scan triggered).

### 6. Verify
```bash
bash status.sh             # health + recent scan runs (read-only)
bash status.sh --run       # also trigger a fresh scan
bash status.sh --hours 48  # widen the Application Insights lookback
```
Confirms the Function App is Running, the `scanner` function published, the managed
identity has its storage role, the Key Vault secrets exist (names only), and shows
recent run telemetry from Application Insights. Results land in the CyberArk
**Discovery & Context** dashboard. The scan also auto-runs every 12 hours.

---

## How `run-deploy.sh` pre-fills the prompts (and why it's safe)

The vendor `deploy.sh` isn't built for automation — it just uses `read -rp`. Since
`read` consumes standard input, `run-deploy.sh` pipes the answers (from `scanner.conf`)
in the exact prompt order, so each `read` picks them up instead of waiting for the
keyboard. The vendor script is untouched.

Safety:
- The CyberArk password is read **hidden** in the wrapper and passed over the stdin
  pipe only — never written to disk, never in process arguments (not visible in `ps`),
  and unset afterwards.
- `preflight.sh`, `status.sh` (default), and `uninstall.sh` (default) are read-only /
  dry-run. Destructive actions require explicit flags and typed confirmation.

---

## Caveats

- **`run-deploy.sh` is coupled to the prompt order** (7 names, then tenant/username/
  password). If a vendor update changes the prompts, update the feed order in the
  wrapper — a small edit, not a re-fork. It also requires a clean state (no
  pre-existing app registration) and guards against it.
- **Flex Consumption** is region-limited; the plan SKU is `FC1`. If a deploy fails on
  "resource operation failed" and everything else is green, check the region.
- **Application Insights** is created in classic mode; Azure may auto-provision a
  default Log Analytics workspace, so `Microsoft.OperationalInsights` must be registered.
- `preflight --validate` covers the ARM deployment only. The **code publish**
  (`config-zip`) and the **CyberArk Identity** side are not covered by `what-if` — if
  something fails post-validation, it's usually one of those. Use `status.sh` to confirm.
- The toolkit assumes one target subscription per `scanner.conf`. For multiple
  environments, keep one conf per environment (e.g. `prod.conf`) and point scripts at it
  with `SCANNER_CONF=prod.conf bash preflight.sh`.
