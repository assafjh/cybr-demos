#!/bin/bash
# This script will deploy a new role-less Conjur node

#================ Internal =======================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
LOGS_FOLDER=$SCRIPT_DIR/../logs

#================ Variables =======================
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Conjur Image URL
CONTAINER_IMG=
# Container Name
CONTAINER_NAME=conjur
# Image TAG
CONTAINER_TAG=
# Where to create the volume directories that Conjur will use
CONTAINER_VOLUME_PATH="$HOME"/conjur
# If using podman, should the script enable a systemd service
IS_CREATE_AUTO_START=false
# Conjur API and UI port
SERVER_PORT=443
# Conjur LB verification port
LB_VERIFICATION_PORT=444
# Conjur database replication port - used for follower and standby communication
DB_PORT=5432
# Conjur audit update port - logs from followers are saved at the Leader Audit DB
AUDIT_REPLICATION_PORT=1999

#================ Script =======================
# Logging
mkdir -p $LOGS_FOLDER
exec > >(tee -a "$LOGS_FOLDER"/02-deploy-new-version-$(date +%Y-%m-%d).log) 2>&1
# Grouping for logging purposes
{
    echo -e "[ Script started ] "

    mkdir -v -p "$CONTAINER_VOLUME_PATH"/"$CONTAINER_NAME"-"$CONTAINER_TAG"/{config,security,backups,seeds,logs,certs}
    cp -v $SCRIPT_DIR/seccomp.json $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"-"$CONTAINER_TAG"/security/

    if [ -z $SUDO ] && [ $(whoami) != "root" ]; then
            echo -e "Enabling usage of port 443 on non-root user"
            sudo sysctl net.ipv4.ip_unprivileged_port_start=443
            echo -e "Enabling linger for non-root user"
            sudo loginctl enable-linger $(whoami)
    fi

    echo -e "Deploying Conjur node"
    $SUDO $CONTAINER_MGR run \
        --name "$CONTAINER_NAME"-"$CONTAINER_TAG" \
        --detach \
        --restart=unless-stopped \
        --security-opt seccomp=$CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"-"$CONTAINER_TAG"/security/seccomp.json \
        --publish "${SERVER_PORT:-443}:443" \
        --publish "${LB_VERIFICATION_PORT:-444}:444" \
        --publish "${DB_PORT:-5432}:5432" \
        --publish "${AUDIT_REPLICATION_PORT:-1999}:1999" \
        --log-driver journald \
        --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"-"$CONTAINER_TAG"/config:/etc/conjur/config:Z \
        --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"-"$CONTAINER_TAG"/security:/opt/cyberark/dap/security:Z \
        --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"-"$CONTAINER_TAG"/backups:/opt/conjur/backup:Z \
        --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"-"$CONTAINER_TAG"/seeds:/opt/cyberark/dap/seeds:Z \
        --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"-"$CONTAINER_TAG"/logs:/var/log/conjur:Z \
        "$CONTAINER_IMG":"$CONTAINER_TAG"

    if [ "$CONTAINER_MGR" == "podman" ] && [ "$IS_CREATE_AUTO_START" == "true" ]; then 
        echo -e "Enabling auto start for podman container"
        $SUDO podman generate systemd "$CONTAINER_NAME"-"$CONTAINER_TAG" --name --container-prefix="" --separator="" > "$SCRIPT_DIR"/conjur.service
            SYSTEMD_FOLDER=system
            if [ $(id -u) -ne 0 ]; then
                    SYSTEMD_FOLDER=user
                    SYSTEMD_FLAG=--user
            fi
        sudo mv "$SCRIPT_DIR"/conjur.service /etc/systemd/$SYSTEMD_FOLDER/conjur.service
        selinuxenabled
        if [ $? -eq 0 ]
        then 
            sudo /sbin/restorecon -v /etc/systemd/$SYSTEMD_FOLDER/conjur.service
        fi
            sudo systemctl $SYSTEMD_FLAG daemon-reload
        sudo systemctl $SYSTEMD_FLAG enable conjur
    fi

    echo -e "[ Script finished ] "
 
} | while read -r line; do echo "$(date +%Y-%m-%d-%H:%M:%S) | " "$line"; done