#!/bin/bash
# This script will restore a backup to a Conjur node
# It is assumed that there is only one instance of conjur running and its role-less
# If you need to use the script on a specific container, change the variable CONTAINER_ID

#================ Internal =======================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
LOGS_FOLDER=$SCRIPT_DIR/../logs
BACKUPS_FOLDER="$SCRIPT_DIR"/../backup

#================ Variables =======================
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Conjur Image URL
CONTAINER_IMG=
# Image TAG
CONTAINER_TAG=
# Conjur container ID
CONTAINER_ID=$($SUDO $CONTAINER_MGR ps | grep "$CONTAINER_IMG":"$CONTAINER_TAG" | awk '{ print $1 }')
# Backup file to restore
BACKUP_FILE=$(find "$BACKUPS_FOLDER" -type f -name '*.tar.xz.gpg' -exec ls -t1 {} + | head -1)

#================ Script =======================
# Logging
mkdir -p $LOGS_FOLDER
exec > >(tee -a "$LOGS_FOLDER"/03-restore-backup-$(date +%Y-%m-%d).log) 2>&1
# Grouping for logging purposes
{
    echo -e "[ Script started ] "

    echo -e "==== Container ID: $CONTAINER_ID ===="

    echo -e "==== Backup to restore: $BACKUP_FILE ===="

    echo -e "Copying backup to Conjur container"
    $SUDO $CONTAINER_MGR cp "$BACKUP_FILE" "$CONTAINER_ID":/opt/conjur/backup/
    $SUDO $CONTAINER_MGR cp "$BACKUPS_FOLDER"/key "$CONTAINER_ID":/opt/conjur/backup/
    $SUDO $CONTAINER_MGR exec "$CONTAINER_ID" ls -ltr /opt/conjur/backup/

    echo -e "Restoring backup"
    $SUDO $CONTAINER_MGR exec "$CONTAINER_ID" sh -c "
        evoke unpack backup --key /opt/conjur/backup/key /opt/conjur/backup/*.tar.xz.gpg
        evoke restore --accept-eula    
    "

    echo -e "Health check"
    curl -k https://127.0.0.1:$CONJUR_PORT/health

    echo -e "[ Script finished ] "
 
} | while read -r line; do echo "$(date +%Y-%m-%d-%H:%M:%S) | " "$line"; done