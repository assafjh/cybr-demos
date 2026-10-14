# Upgrade Conjur Enterprise Version

Upgrade a **single-node demo** Conjur Enterprise (Secrets Manager Self-Hosted) container to a new version.
Run on the Conjur host VM. Not for Standbys, Followers or auto-failover clusters.

## Usage

```bash
vi ./scripts/upgrade.properties                          # registry, docker/podman, sudo

./scripts/00-load-image.sh conjur-appliance_13.10.0.tar.gz   # load the tarball, push it to CONTAINER_IMG
./scripts/01-prepare-upgrade.sh                # back up the running node, stop it, park it
./scripts/02-deploy-new-version.sh             # start a fresh container on the newest local version
./scripts/03-restore-backup.sh                 # restore the backup into it, wait for /health

./scripts/rollback.sh                          # if needed: stop the new one, bring the old one back
```

Each step stands on its own and finds what it needs, so a failed step can be fixed and re-run. The version is typed once, through the tarball name:

- **02** defaults to the highest version of `CONTAINER_IMG` available locally (what 00 just loaded)
- **03** defaults to the version of the running Conjur container (what 02 just started)

Pass a tag to either one to override, e.g. `./scripts/02-deploy-new-version.sh 13.9.0`. Any setting can also be passed from the environment, e.g. `CONTAINER_MGR=podman ./scripts/02-deploy-new-version.sh 13.10.0`.

## What each step does

- **00** - `load`s the image tarball, tags it as `$CONTAINER_IMG:<tag>` (tag from the image name, or from the file name if the tarball has none) and pushes it to the registry. Skip it if the image is already there.
- **01** - finds the single running `conjur-appliance` container, stops the Conjur service, runs `evoke backup`, copies archive + key to `backup/<timestamp>_v<version>/`, then stops the container and renames it `<name>-<version>-pre-upgrade-<timestamp>`.
- **02** - creates volumes under `$CONTAINER_VOLUME_PATH/<name>-<tag>`, extracts the seccomp profile shipped in the new image (`/usr/share/doc/conjur/examples/seccomp.json`, falls back to unconfined), starts `<name>-<tag>`.
- **03** - copies the latest backup in, runs `evoke unpack backup` + `evoke restore`, applies the nginx bypass, waits up to 3 minutes for `/health` to return 200, and prints the command to remove the old container.
- **rollback** - stops the running Conjur container and starts the most recently parked one under its original name.

Old containers are never deleted automatically.

## Podman

Podman has no daemon, so `--restart` doesn't bring a container back after a reboot. With `CONTAINER_MGR=podman` the scripts follow the CyberArk upgrade docs and manage a `conjur.service` systemd unit (`podman generate systemd`):

- **01** stops and disables the unit before parking the old container, so systemd doesn't restart it.
- **02** runs the new container with `--restart=no` and points `conjur.service` at it.
- **rollback** points the unit back at the restored container.

Rootful (`SUDO=sudo` or root) uses a system unit; rootless uses a user unit, persists `ip_unprivileged_port_start=443` in `/etc/sysctl.d/99-conjur.conf` and enables linger.

## Why the nginx bypass

`evoke restore` brings back the hostname/altnames from the node's original `configure`. Nginx host validation (`/etc/nginx/conf.d/is_host_valid.conf`) stays pinned to them - `conjur.yml`, env params and a new custom certificate don't update it. On a demo node upgraded many times since its first configure, 03 sets it to accept any Host header, and fails if the edit doesn't take. Set `ENABLE_NGINX_BYPASS=false` to skip.

## Files

```
upgrade.properties   settings
scripts/common.sh    shared helpers
logs/                one log per step run                (git-ignored)
backup/              backup archive + key per upgrade    (git-ignored - contains the backup key!)
```
