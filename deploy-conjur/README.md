# Deploy Conjur Enterprise

This folder contains scripts to deploy a **CyberArk Conjur Enterprise** cluster using Docker or Podman. The setup provisions one Leader and two Standby nodes, following CyberArk's recommended high-availability architecture.

---

## Architecture

```
┌─────────────┐     Replication     ┌─────────────┐
│   Leader    │ ──────────────────► │  Standby 1  │
│  (conjur01) │                     │  (conjur02) │
└─────────────┘                     └─────────────┘
       │            Replication     ┌─────────────┐
       └────────────────────────── ►│  Standby 2  │
                                    │  (conjur03) │
                                    └─────────────┘
```

---

## Prerequisites

- Docker or Podman installed on each node
- SSH access between the Leader and Standby VMs (required for script 03)
- Access to the CyberArk Conjur Enterprise container image
- All nodes resolvable by hostname

---

## Configuration

All scripts share a single configuration file: `scripts.properties`.

Update this file before running any script.

| Parameter | Description |
|-----------|-------------|
| `SUDO` | Set to `sudo` if required; leave empty to run as current user |
| `CONTAINER_MGR` | Container runtime: `docker` or `podman` |
| `CONTAINER_IMG` | Conjur Enterprise image URL (e.g., `registry.example.com/conjur-appliance`) |
| `CONTAINER_TAG` | Image version tag (e.g., `13.2.0`) |
| `CONTAINER_NAME` | Base name for the container |
| `CONTAINER_VOLUME_PATH` | Host path for persistent volume directories |
| `CONJUR_ADM_PWD` | Admin password for the Conjur account |
| `CONJUR_ORG` | Conjur account name (default: `conjur`) |
| `IS_CREATE_AUTO_START` | Set to `true` to create a systemd service (Podman only) |
| `CONJUR_STANDBY_HOST_1` | Hostname or IP of Standby 1 |
| `CONJUR_STANDBY_HOST_2` | Hostname or IP of Standby 2 |
| `SERVER_PORT` | Conjur API and UI port (default: `443`) |
| `LB_VERIFICATION_PORT` | Load balancer health check port (default: `444`) |
| `DB_PORT` | Database replication port for Followers and Standbys (default: `5432`) |
| `AUDIT_REPLICATION_PORT` | Port for shipping audit logs from Followers to the Leader (default: `1999`) |

---

## Deployment Steps

### Step 1 — Deploy and Configure the Leader

Run the following on the **Leader VM**:

```bash
# 1. Start the Conjur container
./01_deploy_conjur.sh

# 2. Initialize the Leader and generate a standby seed file
./02_configure_leader.sh
```

### Step 2 — Distribute the Seed File to Standbys

Still on the **Leader VM**, copy the seed file to both standbys:

```bash
./03_copy_keys_to_standbys.sh
```

### Step 3 — Deploy and Configure Each Standby

Repeat the following on **Standby 1**, then **Standby 2**:

```bash
# 1. Start the Conjur container
./01_deploy_conjur.sh

# 2. Unpack the seed and join the cluster
./04_configure_standby.sh
```

### Step 4 — Enable Synchronous Replication

Back on the **Leader VM**:

```bash
./05_enable_synchronous_replication.sh
```

---

## Volume Structure

Script 01 creates the following directory layout on each node under `CONTAINER_VOLUME_PATH`:

```
<CONTAINER_VOLUME_PATH>/<CONTAINER_NAME>_<CONTAINER_TAG>/
├── config/     # Conjur configuration files
├── security/   # Encryption keys and certificates
├── backups/    # Database backups
├── seeds/      # Standby seed files
├── logs/       # Conjur application logs
└── certs/      # TLS certificates
```
