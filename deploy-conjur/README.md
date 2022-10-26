# Deploy Conjur
These scripts will quickly deploy Conjur containers.

### Uses
Can be used to deploy Leader and two Standby containers.

### scripts.properties
This file is used as a central configuration file for all scripts, please refer to the below for parameter explanation:
```bash
#==== for scripts internal usage ====
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=podman
# Conjur Image URL
CONTAINER_IMG=
# Container Name
CONTAINER_NAME=conjur_test_01
# Image TAG
CONTAINER_TAG=
# Where to create the volume directories that Conjur will use
CONTAINER_VOLUME_PATH="$HOME"/conjur
# Conjur Admin password
CONJUR_ADM_PWD=SomePass123@
# Conjur account - default is demo
CONJUR_ORG=demo
# If using podman, should the script enable a systemd service
IS_CREATE_AUTO_START=false
# Standby1 hostname
CONJUR_STANDBY_HOST_1=conjur02
# Standby2 hostname
CONJUR_STANDBY_HOST_2=conjur03
# Will be used for Conjur selfsigned certificate, should add here altnames of the Leader instance and the names of the standbys
MASTER_ALTNAMES="$(hostname -s),$CONJUR_STANDBY_HOST_1,$CONJUR_STANDBY_HOST_2"
# Conjur API and UI port
SERVER_PORT=443
# Conjur LB verification port
LB_VERIFICATION_PORT=444
# Conjur database replication port - used for follower and standby communication
DB_PORT=5432
# Conjur audit update port - logs from followers are saved at the Leader Audit DB
AUDIT_REPLICATION_PORT=1999
```
### Steps
1. Update scripts.properties with relevant data
#### Leader
1. Connect to Leader VM
2. Deploy Conjur container
```bash
./01_deploy_conjur.sh
```
3. Configure as container as Leader
```bash
./02_configure_leader.sh
```
#### Standbys
1. Connect to Leader VM.
2. Generate seed file and copy it to the Standbys:
```bash
./03_copy_keys_to_standbys.sh
```
3. Connect to Standby1 VM.
4. Deploy Conjur container:
```bash
./01_deploy_conjur.sh
```
5. Configure as container as Standby:
```bash
./04_configure_standby.sh
```
6. Connect to Standby2 VM.
7. Deploy Conjur container:
```bash
./01_deploy_conjur.sh
```
8. Configure as container as Standby:
```bash
./04_configure_standby.sh
```
9. Connect to the Leader VM.
10. Enable Synchronous replication:
```bash
./05_enable_synchronous_replication.sh
```