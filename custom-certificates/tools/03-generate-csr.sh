#!/bin/bash
# This script will generate a csr for the certificate generated at script #02
# Make sure to edit .env before running this script
#================ Internal ==============
source .env
#================ Script ==============
cd "$SCRIPT_DIR"/../certs || exit 1
openssl req -new -key "$LEAF_PRIVATE_CERTIFICATE_FILE_NAME" -out server.csr -config csr.conf

cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

${SUBJECT_ALT_NAMES}

EOF

