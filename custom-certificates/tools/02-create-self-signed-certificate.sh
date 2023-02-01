#!/bin/bash
# This script will generate a certificate for usage with your application
# Make sure to edit .env before running this script
#================ Internal ==============
source .env
#================ Script ==============
cd "$SCRIPT_DIR"/../certs || exit 1
openssl genrsa -out "$SERVER_KEY_FILE_NAME" 2048
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
