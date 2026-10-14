#!/bin/bash
# Checks the Conjur side BEFORE deploying - the things that broke in the lab were
# all here (missing authenticate permit, empty variables), not in the webhook.
# Run logged in to the Conjur CLI as admin (or a user that can read the branches).
set -uo pipefail

#============ Variables ===============
CONJUR_CLI=conjur
AUTHENTICATOR=conjur/authn-jwt/k8s-cluster1
APPS_BRANCH=data/kubernetes/applications
APPS_GROUP=$APPS_BRANCH/jwt
HOST=$APPS_BRANCH/system:serviceaccount:conjur-webhook-demo:webhook-demo-app
SAFE=$APPS_BRANCH/safe
# Variables the demo apps read
VARIABLES="secret1 secret2 secret3 secret4 secret5 secret6 secret7 secret8"
#============ Script ===============

FAIL=0
ok()   { echo "  ✅ $1"; }
bad()  { echo "  ❌ $1"; echo "     → $2"; FAIL=1; }

echo "Conjur CLI identity: $("$CONJUR_CLI" whoami 2>/dev/null | tr -d '\n' || echo 'NOT LOGGED IN')"

echo "1. Authenticator $AUTHENTICATOR"
if "$CONJUR_CLI" resource show "webservice:$AUTHENTICATOR" >/dev/null 2>&1; then
  ok "webservice exists"
else
  bad "webservice not found" "load kubernetes-jwt/policies/*/03-define-jwt-auth.yml and enable the authenticator"
fi
PERMITTED=$("$CONJUR_CLI" resource permitted-roles "webservice:$AUTHENTICATOR" authenticate 2>/dev/null)
if echo "$PERMITTED" | grep -q ":group:$APPS_GROUP\""; then
  ok "group $APPS_GROUP may authenticate"
else
  bad "group $APPS_GROUP has no 'authenticate' on the authenticator (pods get 403 / CONJ00006E)" \
      "conjur policy update -b $AUTHENTICATOR -f ../policies/02-permit-authenticator.yml"
fi

echo "2. Demo host $HOST"
if "$CONJUR_CLI" list -k host  -s "$HOST" >/dev/null 2>&1; then
  ok "host exists"
  if "$CONJUR_CLI" role memberships "conjur:host:$HOST" 2>/dev/null | grep -q ":group:$APPS_GROUP\""; then
    ok "host is a member of $APPS_GROUP"
  else
    bad "host is not in $APPS_GROUP" "conjur policy update -b data/kubernetes -f ../policies/01-define-webhook-demo-hosts.yml"
  fi
else
  bad "host missing" "conjur policy update -b data/kubernetes -f policies/01-define-webhook-demo-hosts.yml"
fi

echo "3. Variables under $SAFE have values"
for v in $VARIABLES; do
  if "$CONJUR_CLI" variable get -i "$SAFE/$v" >/dev/null 2>&1; then
    ok "$v"
  else
    bad "$v is missing or has no value (provider fails the whole batch with 404)" \
        "run kubernetes-jwt/scripts/02-populate-variables.sh"
  fi
done

echo
if [ "$FAIL" -eq 0 ]; then echo "✅ Conjur side ready."; else echo "❌ Fix the items above before deploying."; fi
exit $FAIL
