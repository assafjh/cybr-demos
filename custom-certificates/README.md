# Import 3rd-party certificates

Conjur Enterprise uses certificates for communication between the Leader and Standby nodes in Conjur cluster. Certificates are required for any Conjur cluster. 

You can use the TLS certificates issued by a third-party instead of Conjur Enterprise self-signed certificates. As part of the Conjur cluster configuration process, you import the certificates received from the third-party onto the Leader. A certificate import replaces any existing certificates on the Leader.

 - The certificates generated in this demo are fulfilling the requirements documented at : [Certificate requirements](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Deployment/HighAvailability/certificate-requirements.htm)
 - This demo assume that you will generate a local CA by using the provided scripts.
 - A custom CA can be used by editing the file ***conjur/.env*** (Block at lines #11 - #15)
```properties
#=========== Root CA details ===========
# Root key file path
ROOT_CA_KEY_PATH="$SCRIPT_DIR"/../certs/rootCA.key
# Root certificate file path
ROOT_CA_CERTIFICATE_PATH="$SCRIPT_DIR"/../certs/rootCA.pem
```
 - Certificates generated can be inspected by using the script:
```bash
tools/05-read-cert.sh <CERTIFICATE_FILE_PATH>
```
- It is recommended to run all the scripts in the Conjur Leader VM machine.

## 1. Generate a local CA
**Note:** Can be skipped if a custom CA is going to be used.

Modify *BYPASS_CA_CN* before running the below.
```bash
BYPASS_CA_CN="Local Certificate Authority" tools/01-create-root-ca.sh
```
A folder named *certs* will be created under the root folder.
The folder will contain two files: *rootCA.key* and *rootCA.pem*

## 2. Import certificates to Conjur
### 1. Configure the scripts
```bash
vi conjur/.env
```
Example:
```properties
#=========== Conjur leader container details ===========
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Conjur Leader port
CONJUR_LEADER_PORT=443
# Conjur Leader container ID
CONTAINER_ID=$(curl -s -k "https://127.0.0.1:$CONJUR_LEADER_PORT/info" | awk '/container/ {print $2}' | tr -d '",')
#=========== Root CA details ===========
# Root key file path
ROOT_CA_KEY_PATH="$SCRIPT_DIR"/../certs/rootCA.key
# Root certificate file path
ROOT_CA_CERTIFICATE_PATH="$SCRIPT_DIR"/../certs/rootCA.pem
#=========== Leader certificate details ===========
# Generated Key filename
LEADER_KEY_FILE_PATH="$SCRIPT_DIR"/../certs/custom-conjur-leader.key
# Generated Certificate filename
LEADER_CERTIFICATE_FILE_PATH="$SCRIPT_DIR"/../certs/custom-conjur-leader.pem
# Leader CN
LEADER_CN="conjur-leader.example.local"
# Leader SAN
LEADER_SUBJECT_ALT_NAMES='
[alt_names]
DNS.1 = localhost
DNS.2 = conjur-leader
IP.1 = 127.0.0.1
'
#=========== Follower certificate details ===========
# Generated Key filename
FOLLOWER_KEY_FILE_PATH="$SCRIPT_DIR"/../certs/custom-conjur-follower.key
# Generated Certificate filename
FOLLOWER_CERTIFICATE_FILE_PATH="$SCRIPT_DIR"/../certs/custom-conjur-follower.pem
# Follower CN
# Must be according the follower service kubernetes FQDN
# For example: <service>.<namespace>.svc.cluster.local
FOLLOWER_CN="conjur-follower.conjur-namespace.svc.cluster.local"
# Follower SAN
# 2 SAN records must be provided:
# <service>, <service>.<namespace>
FOLLOWER_SUBJECT_ALT_NAMES='
[alt_names]
DNS.1 = conjur-follower
DNS.2 = conjur-follower.conjur-namespace
'
```
### 2. Generate Leader certificate
**Note**: unless modified at the .*env* file, generated certificates will be saved to the folder *certs*.
```bash
conjur/01-generate-leader-certificates.sh
```
### 2. Load certificates to Leader
* This script is meant to use at the Conjur Leader VM machine.
* Make sure that the certificates are accessible to the script
```bash
conjur/02-load-leader-certificates-to-leader.sh
```
### 3. Generate Follower certificate
* This step is optional, needed only if Followers are going to be used.
* Unless modified at the .*env* file, generated certificates will be saved to the folder *certs*.
```bash
conjur/03-generate-follower-certificate.sh
```
### 4. Load certificates to Leader
* This step is optional, needed only step #3 is done.
* This script is meant to use at the Conjur Leader VM machine.
* Make sure that the certificates are accessible to the script
```bash
conjur/04-load-follower-certificate-to-leader.sh
```
## How to check that the certificates were loaded to Conjur
#### 1. UI - Relevant to Leader
You can check that the certificate has changed by navigating to Conjur UI page at the browser.
#### 2. Inside Conjur leader container - Relevant to Leader and Followers
- exec into the Leader container, all custom certificates were saved at the folder */certs/*
- Conjur loaded certificates are copied to and soft linked at the folder */opt/conjur/etc/ssl*
- The openssl command can help to read the certificates
```bash
openssl x509 -text -noout -in $CERTIFICATE
```
