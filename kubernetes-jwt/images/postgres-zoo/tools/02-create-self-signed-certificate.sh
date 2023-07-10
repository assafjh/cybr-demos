#!/bin/bash
# This script will generate a certificate for usage with your application
# Make sure to edit .env before running this script
#================ Internal ==============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
source $SCRIPT_DIR/.env
#================ Script ==============
cd "$SCRIPT_DIR"/../certs || exit 1

[ -n "$BYPASS_SERVER_KEY_FILE_PATH" ] && SERVER_KEY_FILE_PATH="$BYPASS_SERVER_KEY_FILE_PATH"
[ -n "$BYPASS_SERVER_CN" ] && SERVER_CN="$BYPASS_SERVER_CN"

openssl genrsa -out "$SERVER_KEY_FILE_PATH" 2048
cat > csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
C = IL
ST = Hamerkaz
L = Tel-Aviv
O = Org
OU = DevSecOps
CN = ${SERVER_CN}

EOF
