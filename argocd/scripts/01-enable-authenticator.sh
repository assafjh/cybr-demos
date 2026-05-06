#!/bin/bash
set -euo pipefail

#============ Variables ===============
AUTHN_TO_ENABLE=authn-jwt/k8s-argocd1
CONJUR_CLI=conjur

#============ Script ===============
"$CONJUR_CLI" whoami
"$CONJUR_CLI" authenticator enable --id "${AUTHN_TO_ENABLE}"