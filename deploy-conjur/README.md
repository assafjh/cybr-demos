# Deploy Conjur Enterprise

Deploy a **single-node demo** Conjur Enterprise (Secrets Manager Self-Hosted) Leader with Docker or Podman, for demos and POCs.

Containers use the same layout as [`upgrade-conjur-enterprise-version`](../upgrade-conjur-enterprise-version), so a node deployed here can be upgraded with it. For Followers, see [`kubernetes-follower`](../kubernetes-follower) - they fetch their seed from this Leader through the seed generation service.

## Usage

```bash
cd scripts
vi deploy.properties                                     # registry, docker/podman, hostname, altnames

./00-load-image.sh conjur-appliance_13.10.0.tar.gz      # load the tarball, push it to CONTAINER_IMG
./01-deploy-container.sh                                 # start the container (newest local version)
./02-configure-leader.sh                                 # configure as Leader, wait for /health
```

`02` prompts for the admin password unless `CONJUR_ADMIN_PASSWORD` is set. Don't commit it to `deploy.properties`.

The Leader comes up with self-signed certificates. To use your own CA instead (Leader certificate, and the Follower certificate for Kubernetes followers - which can be loaded any time later), run [`custom-certificates/conjur`](../custom-certificates) after step 02.

## Configuration (`scripts/deploy.properties`)

| Setting | Default | Notes |
|---|---|---|
| `SUDO`, `CONTAINER_MGR`, `CONTAINER_IMG`, `CONTAINER_NAME`, `CONTAINER_VOLUME_PATH` | | Same as in the upgrade scripts - keep them in sync |
| `CONJUR_ACCOUNT` | `conjur` | |
| `CONJUR_ADMIN_PASSWORD` | empty | Empty = prompt |
| `CONJUR_HOSTNAME` | `hostname -f` | Name clients use to reach Conjur |
| `LEADER_ALTNAMES` | empty | Extra certificate names, comma separated. This host's FQDN/short name and `localhost` are added automatically |

**Set the names right the first time.** The hostname and altnames given at configure time survive every backup/restore and upgrade, and nginx host validation stays pinned to them. On a long-lived demo node, the only way around a name you didn't list is the bypass in the upgrade scripts.

## What each step does

- **00** - `load`s the image tarball, tags it as `$CONTAINER_IMG:<tag>` (tag from the image name, or from the file name if the tarball has none) and pushes it to the registry.
- **01** - creates volumes under `$CONTAINER_VOLUME_PATH/<name>-<tag>`, extracts the seccomp profile shipped in the image (falls back to unconfined), starts `<name>-<tag>`. With Podman, also installs a `conjur.service` systemd unit so Conjur comes back after a reboot.
- **02** - `evoke configure leader` with the hostname and altnames, waits for `/health`.

Server keys are not encrypted with a master key - demo setup.
