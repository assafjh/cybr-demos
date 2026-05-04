#!/bin/sh
# ---------------------------------------------------------------
# entry-point.sh — prints context depending on the auth mode,
# then delegates to retrieve.sh
#
# AUTH_MODE:
#   pre-authenticated  — token already injected by sidecar (cert / JWT)
#   self-authenticated — app exchanges its own JWT for a token
# ---------------------------------------------------------------
echo "======================"
if [ "${AUTH_MODE:-pre-authenticated}" = "self-authenticated" ]; then
  echo "Mode: self-authenticated (JWT)"
  echo "Using Service Account JWT - taken from file:"
  ls -ltr /var/run/secrets/kubernetes.io/serviceaccount/token
else
  echo "Mode: pre-authenticated (sidecar)"
  echo "Using Conjur Access Token - injected by authenticator client sidecar:"
  ls -ltr /run/conjur/access-token
fi
echo "======================"
./retrieve.sh
sleep infinity
