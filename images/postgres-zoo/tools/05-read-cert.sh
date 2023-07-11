#!/bin/bash
# Use this script in order to read certificate content
#================ Validations ==============
[ $# -ne 1 ] && printf "expecting one parameter.\nSyntax: 05-read-cert.sh <CERTIFICATE_FILE_PATH>\n" && exit 1
[ ! -f "$1" ] && printf "certificate file does not exist or path is not correct\n" && exit 1
#================ Script ==============
openssl x509 -text -noout -in "$1"