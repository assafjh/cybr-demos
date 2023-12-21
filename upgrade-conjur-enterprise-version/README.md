# Upgrade Conjur Enterprise Version
These scripts will quickly upgrade Conjur Enterprise containers.
Scripts needs to be run from Conjur container host VM

## This script is meant to demo purposes only and it is assumed that the node being upgraded is a demo server

### Uses
Can be used to upgrade VM based Conjur Enterprise containers.

#### 01-prepare-upgrade.sh

###### Purpose

This script automates the preparation of Conjur Enterprise for an upgrade, primarily by backing it up and stopping relevant processes. It's designed for environments where Conjur Enterprise is not configured with auto-failover.

###### Key Steps

1. Logging Setup
   - Creates a "logs" folder to store log files generated during the process.
   - Redirects the script's output to a log file named with the date and time for tracking purposes.

2. Information Gathering
   - Retrieves the ID of the Conjur container.
   - Determines the Conjur version currently in use.
   - Identifies the container manager employed (Docker or Podman).

3. Backup Preparation
   - Disables the Conjur node, ensuring it's inactive for the backup process.
   - Stops replication on Standbys and Followers (repeated twice for emphasis).

4. Conjur Node Backup
   - Initiates a backup of the Conjur node, capturing its data for potential restoration.
   - Locates the most recently created backup file within the container's filesystem.
   - Creates a "backup" folder to store the retrieved backup.
   - Copies both the backup file and its associated key to the designated backup folder for safekeeping.

5. Container Management
   - Stops the Conjur container, halting its operations.
   - Renames the container to a descriptive name that includes the Conjur version and a timestamp, facilitating identification and version tracking.

6. Logging Completion
   - Records a log message indicating the script's successful completion.

###### Configuration Items

| Configuration Item | Description | Default Value | Notes |
|---|---|---|---|
| `SUDO` | Prefix for commands requiring elevated privileges (if needed) | Empty string (not used by default) | |
| `CONTAINER_MGR` | Container manager to use (Docker or Podman) | `docker` | |
| `CONJUR_PORT` | Port on which Conjur is running | `443` | |
| `BACKUPS_FOLDER` | Location to store backup files | `...logs/../backup` | Can be changed to a custom directory |
| `LOGS_FOLDER` | Location to store log files | `...logs` | Can be changed to a custom directory |
| `CONTAINER_BACKUP_NAME` | Name for the renamed Conjur container | `CONJUR-v$CONJUR_VERSION-$(date +%Y-%m-%d-%s)` | Can be customized further for better identification |
| `CONTAINER_ID` | ID of the Conjur container | Dynamically retrieved from Conjur | Can be manually set if needed |
| `CONJUR_VERSION` | Version of Conjur currently running | Dynamically retrieved from Conjur | Can be manually set if needed |

###### Modifying Configuration

To adjust these configuration items, edit the values near the beginning of the script:

```bash
# ...
BACKUPS_FOLDER=... # Optional manual setting
LOGS_FOLDER=... # Optional manual setting
SUDO=
CONTAINER_MGR=docker
CONJUR_PORT=443
CONTAINER_ID="your_container_id"  # Optional manual setting
CONJUR_VERSION="your_conjur_version"  # Optional manual setting
CONTAINER_BACKUP_NAME=... # Optional manual setting
# ...
```

###### Additional Notes

- The script assumes Conjur is running on port 443.
- It may require `sudo` privileges for certain commands, depending on the container configuration.
- It's specifically intended for use with Conjur Enterprise environments that lack auto-failover functionality.

#### 02-deploy-new-version.sh

##### Purpose

This script automates the deployment of a new Conjur node without any pre-assigned roles. It handles container setup, volume creation, port mapping, and optional auto-start configuration for podman.

##### Key Steps

1. Logging Setup
   - Creates a "logs" folder to store log files.
   - Redirects the script's output to a timestamped log file for tracking.

2. Directory Creation
   - Creates a directory structure for the Conjur node's volumes, including config, security, backups, seeds, logs, and certs folders.
   - Copies a `seccomp.json` file (presumably for security configuration) into the security folder.

3. Port Access for Non-Root Users
   - If the script is not running with `sudo` and the current user is not root:
     - Enables usage of port 443 for non-root users.
     - Enables session lingering for the current user.

4. Conjur Node Deployment
   - Starts a new container using the specified container manager (`docker` or `podman`) with the following settings:
     - Name: `CONJUR_NAME-CONJUR_TAG`
     - Detached mode (runs in the background)
     - Restart policy: Restart unless stopped
     - Security option: Applies the `seccomp.json` file
     - Port mappings for Conjur API/UI, LB verification, database replication, and audit replication
     - Log driver: journald
     - Volume mounts for the created directories

5. Auto-Start Configuration for Podman (Optional)
   - If using podman and `IS_CREATE_AUTO_START` is set to true:
     - Generates a systemd service file for the container.
     - Moves the service file to the appropriate systemd folder (system or user).
     - Reloads systemd daemons.
     - Enables the Conjur service for automatic startup.

##### Configuration Items

| Configuration Item | Description | Default Value | Notes |
|---|---|---|---|
| `SUDO` | Prefix for commands requiring elevated privileges (if needed) | Empty string (not used by default) | - Useful for commands like enabling port 443 for non-root users. |
| `CONTAINER_MGR` | Container manager to use (Docker or Podman) | `docker` | |
| `CONTAINER_IMG` | Conjur image URL | Must be provided | - Specify the URL of the desired Conjur image. |
| `CONTAINER_NAME` | Container name | `conjur` | - Can be customized for better identification. |
| `CONTAINER_TAG` | Image tag | Must be provided | - Specify the desired tag for the Conjur image. |
| `CONTAINER_VOLUME_PATH` | Base path for Conjur volume directories | `$HOME/conjur` | - Define the root location for storing Conjur data. |
| `LOGS_FOLDER` | Location to store log files | `../logs` | - Specify a custom directory for script logs if needed. |
| `IS_CREATE_AUTO_START` | Enable auto-start for podman container | `false` | - Set to `true` to create a systemd service for podman auto-start. |
| `SERVER_PORT` | Conjur API and UI port | `443` | - Modify if Conjur is running on a different port. |
| `LB_VERIFICATION_PORT` | Conjur LB verification port | `444` | |
| `DB_PORT` | Conjur database replication port | `5432` | |
| `AUDIT_REPLICATION_PORT` | Conjur audit update port | `1999` | |

###### Modifying Configuration

To adjust the configuration items, locate the section near the beginning of the script that defines them:

```bash
# ...
SUDO=
CONTAINER_MGR=docker
CONTAINER_IMG=
# ... (other variables)
```

Edit the values directly within this section to match your desired settings. For example, to use Podman as the container manager and specify a Conjur image URL:

```bash
CONTAINER_MGR=podman
CONTAINER_IMG=my-repo/conjur-img:latest
```

Remember to save the changes to the script file for the modifications to take effect.

##### Additional Notes

- The script assumes Conjur listens on port 443 by default.
- It may require `sudo` privileges for certain commands, depending on the container configuration and user permissions.
- It's specifically designed for deploying a new Conjur node without pre-assigned roles.

#### Explanation of the Bash Script for Restoring a Backup to a Conjur Node

##### Purpose

This script automates the process of restoring a backup to a Conjur node. It's designed for environments with a single, role-less Conjur instance.

##### Key Steps

1. Logging Setup
   - Creates a "logs" folder to store log files.
   - Redirects the script's output to a timestamped log file for tracking.

2. Information Gathering
   - Identifies the Conjur container ID using the specified container manager (`docker` or `podman`).
   - Locates the most recently created backup file within the designated backup folder.

3. Backup File Copying
   - Copies the backup file and its associated key to the Conjur container's `/opt/conjur/backup` directory.
   - Lists the contents of the backup directory within the container to verify successful transfer.

4. Backup Restoration
   - Executes commands within the Conjur container to:
     - Unpack the backup file using the provided key.
     - Initiate the restoration process, accepting the Conjur EULA.

5. Health Check
   - Performs a basic health check on the Conjur node by making a request to its health endpoint.

##### Configuration Items

| Configuration Item | Description | Default Value | Notes |
|---|---|---|---|
| `SUDO` | Prefix for commands requiring elevated privileges (if needed) | Empty string (not used by default) | |
| `CONTAINER_MGR` | Container manager to use (Docker or Podman) | `docker` | |
| `CONTAINER_IMG` | Conjur image URL | Must be provided | |
| `CONTAINER_TAG` | Image tag | Must be provided | |
| `LOGS_FOLDER` | Location to store log files | `../logs` | |
| `BACKUPS_FOLDER` | Location of backup files | `../backup` | |
| `CONJUR_PORT` | Conjur API and UI port | (Not explicitly defined in the script) | Assumed to be 433 for health check |

##### Modifying Configuration

To adjust the configuration items, locate the section near the beginning of the script that defines them:

```bash
# ...
SUDO=
CONTAINER_MGR=docker
CONTAINER_IMG=
# ... (other variables)
```

Edit the values directly within this section to match your desired settings. Remember to save the changes to the script file for the modifications to take effect.

##### Additional Notes

- The script assumes there's only one role-less Conjur instance running.
- It expects backup files to be in `.tar.xz.gpg` format.
- It automatically accepts the Conjur EULA during restoration.
- It performs a basic health check using `curl`.
- It's crucial to provide the correct Conjur image URL and tag for successful container identification.
