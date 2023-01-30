#!/bin/bash
# This script is checking if the values we have populated at the K8s Cert Authn are valid.
#========== Script ===============
# Retriving the Kubernetes API certificate chain we have at Conjur
CERT="$(conjur variable get -i conjur/authn-k8s/k8s-follower1/kubernetes/ca-cert)"
# Saving cert to file
echo "$CERT" > ./kube-api-public-key-from-conjur.pem
# Retriving the SA JWT we have at Conjur
TOKEN="$(conjur variable get -i conjur/authn-k8s/k8s-follower1/kubernetes/service-account-token)"
# Retriving the Kubernetes API URL we have at Conjur
API="$(conjur variable get -i conjur/authn-k8s/k8s-follower1/kubernetes/api-url)"
# Test
if [[ "$(curl -s --cacert kube-api-public-key-from-conjur.pem --header "Authorization: Bearer ${TOKEN}" "$API"/healthz)" == "ok" ]]; then
  echo "Service account access to kubernetes API verified."
else
  echo
  echo ">>> Service account access to kubernetes API NOT verified. <<<"
  echo
fi
# Cleanup
rm -f ./kube-api-public-key-from-conjur.pem