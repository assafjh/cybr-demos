#!/bin/bash
#========== Script ===============
CERT="$(conjur variable get -i conjur/authn-k8s/k8s-cluster1/kubernetes/ca-cert)"
TOKEN="$(conjur variable get -i conjur/authn-k8s/k8s-cluster1/kubernetes/service-account-token)"
API="$(conjur variable get -i conjur/authn-k8s/k8s-cluster1/kubernetes/api-url)"
echo "$CERT" > ./kube-api-public-key-from-conjur.pem
if [[ "$(curl -s --cacert kube-api-public-key-from-conjur.pem --header "Authorization: Bearer ${TOKEN}" "$API"/healthz)" == "ok" ]]; then
  echo "Service account access to kubernetes API verified."
else
  echo
  echo ">>> Service account access to kubernetes API NOT verified. <<<"
  echo
fi
rm -f ./kube-api-public-key-from-conjur.pem