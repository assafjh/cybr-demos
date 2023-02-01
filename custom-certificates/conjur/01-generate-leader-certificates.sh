#!/bin/bash
#============ Internal ===============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR"/.env
#============ Script ===============
BYPASS_SERVER_CN="$LEADER_CN" BYPASS_SERVER_KEY_FILE_PATH="$LEADER_KEY_FILE_PATH" "$SCRIPT_DIR"/../tools/02-create-self-signed-certificate.sh
BYPASS_SERVER_KEY_FILE_PATH="$LEADER_KEY_FILE_PATH" BYPASS_SUBJECT_ALT_NAMES="$LEADER_SUBJECT_ALT_NAMES" "$SCRIPT_DIR"/../tools/03-generate-csr.sh
BYPASS_CA_CERTIFICATE_FILE_PATH="$ROOT_CA_CERTIFICATE_PATH" BYPASS_CA_KEY_FILE_PATH="$ROOT_CA_KEY_PATH" BYPASS_SERVER_CERTIFICATE_FILE_PATH="$LEADER_CERTIFICATE_FILE_PATH" "$SCRIPT_DIR"/../tools/04-sign-csr.sh

