#!/bin/bash
set -euo pipefail

#============ Variables ===============
CONJUR_HOST="${CONJUR_HOST:-"<your-tenant>.secretsmgr.cyberark.cloud"}"
PORT=443

#============ Script ===============
openssl s_client -showcerts -connect "${CONJUR_HOST}:${PORT}" < /dev/null 2>/dev/null \
  | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > conjur.crt

echo "Certificate saved to conjur.crt"