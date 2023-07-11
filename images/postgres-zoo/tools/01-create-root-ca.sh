#!/bin/bash
# This script will generate a Root Certificate for local CA purpose
# Make sure to edit .env before running this script
#================ Internal ==============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
source $SCRIPT_DIR/.env
#================ Script ==============
[ ! -d "$SCRIPT_DIR/../certs" ] && mkdir "$SCRIPT_DIR"/../certs

[ -n "$BYPASS_CA_CN" ] && CA_CN="$BYPASS_CA_CN"

cd "$SCRIPT_DIR"/../certs || exit 1
openssl req -x509 \
            -sha256 -days 3560 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=$CA_CN/C=IL/L=Tel-Aviv" \
            -keyout rootCA.key -out rootCA.pem 
