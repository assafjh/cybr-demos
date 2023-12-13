#!/bin/bash
# This script will prepare Conjur Enterprise for upgrade
# Do note that it is assumed Conjur Enterprise is not configured with auto-failover.

#================ Internal =======================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
LOGS_FOLDER=$SCRIPT_DIR/../logs
BACKUPS_FOLDER="$SCRIPT_DIR"/../backup

#================ Variables =======================
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Conjur port
CONJUR_PORT=443
# Conjur container ID
CONTAINER_ID=$(curl -s -k "https://127.0.0.1:$CONJUR_PORT/info" | awk '/container/ {print $2}' | tr -d '",')
# Conjur backup container name
CONJUR_VERSION=$(curl -s -k "https://127.0.0.1:$CONJUR_PORT/info" | awk '/release/ {print $2}' | tr -d '",')
CONTAINER_BACKUP_NAME=CONJUR-v$CONJUR_VERSION-$(date +%Y-%m-%d-%s)

#================ Script =======================
# Logging
mkdir -p $LOGS_FOLDER
exec > >(tee -a "$LOGS_FOLDER"/01-prepare-upgrade-$(date +%Y-%m-%d).log) 2>&1
# Grouping for logging purposes
{
    echo -e "[ Script started ] "

    echo -e "==== Container ID: $CONTAINER_ID ===="

    echo -e "==== Disabling Conjur Node ===="
    $SUDO $CONTAINER_MGR exec "$CONTAINER_ID" sv stop conjur

    echo -e "==== Stop replication on Standbys and Followers ===="
    $SUDO $CONTAINER_MGR exec "$CONTAINER_ID" evoke replication stop

    echo -e "==== Stop replication on Standbys and Followers ===="
    $SUDO $CONTAINER_MGR exec "$CONTAINER_ID" evoke replication stop

    echo -e "==== Backing up Node ===="
    $SUDO $CONTAINER_MGR exec "$CONTAINER_ID" evoke backup

    echo -e "Locating backup file"
    BACKUP_FILE=$($SUDO $CONTAINER_MGR exec "$CONTAINER_ID"  find /opt/conjur/backup/ -type f -name '*.tar.xz.gpg' -exec ls -t1 {} + | head -1)

    echo -e "File name: $BACKUP_FILE"

    echo -e "Creating folder: $SCRIPT_DIR/backup"
    mkdir -v -p $SCRIPT_DIR/backup

    echo -e "Copying backup from Conjur container"
    $SUDO $CONTAINER_MGR cp "$CONTAINER_ID":"$BACKUP_FILE" "$BACKUPS_FOLDER"/
    $SUDO $CONTAINER_MGR cp "$CONTAINER_ID":/opt/conjur/backup/key "$BACKUPS_FOLDER"/
    ls -ltr "$BACKUPS_FOLDER"/*

    echo -e "Stopping Conjur container"
    $SUDO $CONTAINER_MGR stop "$CONTAINER_ID"

    echo -e "Renaming Conjur container to $CONTAINER_BACKUP_NAME"
    $SUDO $CONTAINER_MGR rename "$CONTAINER_ID" "$CONTAINER_BACKUP_NAME"

    echo -e "[ Script finished ] "
 
} | while read -r line; do echo "$(date +%Y-%m-%d-%H:%M:%S) | " "$line"; done