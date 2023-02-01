#!/bin/bash
# This script will sign the csr using the root ca that script #01 has generated
# Make sure to edit .env before running this script
#================ Internal ==============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
source $SCRIPT_DIR/.env
#================ Script ==============
cd "$SCRIPT_DIR"/../certs || exit 1

[ -n "$BYPASS_CA_CERTIFICATE_FILE_PATH" ] && CA_CERTIFICATE_FILE_PATH="$BYPASS_CA_CERTIFICATE_FILE_PATH"
[ -n "$BYPASS_CA_KEY_FILE_PATH" ] && CA_KEY_FILE_PATH="$BYPASS_CA_KEY_FILE_PATH"
[ -n "$BYPASS_SERVER_CERTIFICATE_FILE_PATH" ] && SERVER_CERTIFICATE_FILE_PATH="$BYPASS_SERVER_CERTIFICATE_FILE_PATH"

CA_KEY_BASE_FILE_PATH="${CA_KEY_FILE_PATH%.*}"

OPENSSL_SERIAL_COMMAND="-CAcreateserial"
[ -f "$CA_KEY_BASE_FILE_PATH".srl ] && OPENSSL_SERIAL_COMMAND="-CAserial $CA_KEY_BASE_FILE_PATH.srl"

openssl x509 -req \
    -in server.csr \
    -CA "$CA_CERTIFICATE_FILE_PATH" -CAkey "$CA_KEY_FILE_PATH" \
    $OPENSSL_SERIAL_COMMAND -out "$SERVER_CERTIFICATE_FILE_PATH" \
    -days 3650 \
    -sha256 -extfile cert.conf
