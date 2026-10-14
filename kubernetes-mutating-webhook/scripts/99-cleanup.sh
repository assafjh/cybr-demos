#!/bin/bash

set -uo pipefail

#============ Variables ===============
# Using kubectl/oc
COP_CLI=kubectl
#============ Script ===============

# Webhook first, so nothing is blocked while the injector goes away
"$COP_CLI" delete mutatingwebhookconfiguration conjur-injector --ignore-not-found
"$COP_CLI" delete namespace conjur-webhook-demo --ignore-not-found
"$COP_CLI" delete namespace conjur-injector --ignore-not-found
