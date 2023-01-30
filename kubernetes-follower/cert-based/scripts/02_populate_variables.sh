#!/bin/bash
#============ Variables ===============
# Using kubectl/oc
COP_CLI=kubectl
#============ Script ===============
# Retrieving Kubernetes API URL
COP_API_URL="$($COP_CLI config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')"
# Retrieving SA JWT secret name
TOKEN_SECRET_NAME="$($COP_CLI get secrets -n conjur-cert | grep "conjur-demo-acct.*service-account-token" | head -n1 | awk '{print $1}')"
# Retrieving JWT
SA_TOKEN=$($COP_CLI get secret $TOKEN_SECRET_NAME -n conjur-cert --output='go-template={{ .data.token }}' | base64 -d)
# Below are different methods to get the Kubernetes API certificate, comment and uncomment as needed.
# General:
# openssl s_client -showcerts -connect $KUBE_API_HOST:6443 < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ./kube-api-public-key.pem
# K3S:
#$COP_CLI get secret k3s-serving -n kube-system -o json --output='jsonpath={.data.tls\.crt}'  | base64 --decode > ./kube-api-public-key.pem
# Rancher: 
# $COP_CLI get secret tls-rancher-internal-ca -n cattle-system -o yaml
# EKS, OCP:
$COP_CLI get secret "$TOKEN_SECRET_NAME" -n conjur-cert -o json --output='jsonpath={.data.ca\.crt}'  | base64 --decode > ./kube-api-public-key.pem
#==========

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Generating certificates for the authenticator
CONFIG="
[ req ]
distinguished_name = dn
x509_extensions = v3_ca
[ dn ]
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
"
openssl genrsa -out ./authn-generated-ca.key 2048
openssl req -x509 -new -nodes -key ./authn-generated-ca.key -sha1 -days 3650 -set_serial 0x0 -out ./authn-generated-ca.cert \
  -subj "/CN=conjur.authn-k8s.k8s-follower1/OU=Conjur Kubernetes CA/O=demo" \
  -config <(echo "$CONFIG")
openssl x509 -in ./authn-generated-ca.cert -text -noout

# Populate authenticator values
conjur variable set -i "conjur/authn-k8s/k8s-follower1/ca/key" -v "$(cat ./authn-generated-ca.key)"
conjur variable set -i "conjur/authn-k8s/k8s-follower1/ca/cert" -v "$(cat ./authn-generated-ca.cert)"
conjur variable set -i "conjur/authn-k8s/k8s-follower1/kubernetes/service-account-token" -v "$SA_TOKEN"
conjur variable set -i "conjur/authn-k8s/k8s-follower1/kubernetes/ca-cert" -v "$(cat ./kube-api-public-key.pem)"
conjur variable set -i "conjur/authn-k8s/k8s-follower1/kubernetes/api-url" -v "$COP_API_URL"
