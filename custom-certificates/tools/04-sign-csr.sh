#!/bin/bash
# This script will sign the csr using the root ca that script #01 has generated
# Make sure to edit .env before running this script
#================ Internal ==============
source .env
#================ Script ==============
cd "$SCRIPT_DIR"/../certs || exit 1
openssl x509 -req \
    -in server.csr \
    -CA "$CA_PUB_FILE_NAME" -CAkey "$CA_PRIV_FILE_NAME" \
    -CAcreateserial -out "$LEAF_PUBLIC_CERTIFICATE_FILE_NAME" \
    -days 3650 \
    -sha256 -extfile cert.conf
