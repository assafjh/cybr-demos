#!/bin/bash
#============ Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/scripts.properties
#========== Script ===============
mkdir -p "$CONTAINER_VOLUME_PATH"/"$CONTAINER_NAME"_"$CONTAINER_TAG"/{config,security,backups,seeds,logs,certs}
cp -v $SCRIPT_DIR/seccomp.json $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"_"$CONTAINER_TAG"/security/

if [ -z $SUDO ] && [ $(whoami) != "root" ]; then
        sudo sysctl net.ipv4.ip_unprivileged_port_start=443
        sudo loginctl enable-linger $(whoami)
fi

$SUDO $CONTAINER_MGR run \
    --name "$CONTAINER_NAME"_"$CONTAINER_TAG" \
    --detach \
    --restart=unless-stopped \
    --security-opt seccomp=$CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"_"$CONTAINER_TAG"/security/seccomp.json \
    --publish "${SERVER_PORT:-443}:443" \
    --publish "${LB_VERIFICATION_PORT:-444}:444" \
    --publish "${DB_PORT:-5432}:5432" \
    --publish "${AUDIT_REPLICATION_PORT:-1999}:1999" \
    --log-driver journald \
    --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"_"$CONTAINER_TAG"/config:/etc/conjur/config:Z \
    --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"_"$CONTAINER_TAG"/security:/opt/cyberark/dap/security:Z \
    --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"_"$CONTAINER_TAG"/backups:/opt/conjur/backup:Z \
    --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"_"$CONTAINER_TAG"/seeds:/opt/cyberark/dap/seeds:Z \
    --volume $CONTAINER_VOLUME_PATH/"$CONTAINER_NAME"_"$CONTAINER_TAG"/logs:/var/log/conjur:Z \
    "$CONTAINER_IMG":"$CONTAINER_TAG"

if [ "$CONTAINER_MGR" == "podman" ] && [ "$IS_CREATE_AUTO_START" == "true" ]; then 
	$SUDO podman generate systemd "$CONTAINER_NAME"_"$CONTAINER_TAG" --name --container-prefix="" --separator="" > "$SCRIPT_DIR"/conjur.service
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

