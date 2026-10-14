#!/bin/bash

set -euo pipefail

#============ Variables ===============
# Using kubectl/oc
COP_CLI=kubectl
# Namespace of the kubernetes-jwt demo - its conjur-connect ConfigMap is the source of the connection details
SOURCE_NAMESPACE=conjur-jwt
# Namespace the injector runs in, leave as is
INJECTOR_NAMESPACE=conjur-injector
# Injector image - built by .github/workflows/images.yml
INJECTOR_IMAGE=${INJECTOR_IMAGE:-"ghcr.io/assafjh/conjur-injector:latest"}
# Conjur policy branch holding the JWT hosts (must match identity-path of the authenticator)
CONJUR_IDENTITY_PATH=data/kubernetes/applications
INJECTOR_PULL_POLICY=${INJECTOR_PULL_POLICY:-"Always"}   # IfNotPresent for a locally loaded image
# Images the injector adds to pods
PROVIDER_IMAGE=${PROVIDER_IMAGE:-"cyberark/secrets-provider-for-k8s:latest"}
SUMMON_IMAGE=${SUMMON_IMAGE:-"ghcr.io/assafjh/conjur-summon-bin:latest"}
# labeled = only namespaces labeled conjur.org/injection=enabled
# all     = every namespace except system ones (demo environments; pod annotation is the only opt-in)
INJECT_SCOPE=${INJECT_SCOPE:-"labeled"}
# Fail = pods in scope are not created while the injector is down; Ignore = they start un-injected.
# Defaults: Fail for labeled, Ignore for all (a down injector must not stop the whole cluster)
if [ "$INJECT_SCOPE" = "all" ]; then FAILURE_POLICY=${FAILURE_POLICY:-"Ignore"}; else FAILURE_POLICY=${FAILURE_POLICY:-"Fail"}; fi
# Secrets Provider image runs as a named user (uid 777); pin it so runAsNonRoot can be verified.
# Auto: 0 (unset) on OpenShift, where the SCC assigns the uid; 777 elsewhere. Override with PROVIDER_RUN_AS_USER.
# Days the self-signed webhook certificate is valid
CERT_DAYS=365
#============ Script ===============

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "${PROVIDER_RUN_AS_USER:-}" ]; then
  # capture first: with pipefail, grep -q exiting early could fail the pipeline
  OCP_RESOURCES=$("$COP_CLI" api-resources --api-group=security.openshift.io -o name 2>/dev/null || true)
  if [[ "$OCP_RESOURCES" == *securitycontextconstraints* ]]; then
    PROVIDER_RUN_AS_USER=0
    echo "--- OpenShift detected: the SCC assigns the provider uid (PROVIDER_RUN_AS_USER=0)"
  else
    PROVIDER_RUN_AS_USER=777
  fi
fi
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
SERVICE_DNS="conjur-injector.${INJECTOR_NAMESPACE}.svc"

echo "--- Reading Conjur connection details from $SOURCE_NAMESPACE/conjur-connect"
cm() { "$COP_CLI" get configmap conjur-connect -n "$SOURCE_NAMESPACE" -o jsonpath="{.data.$1}"; }
CONJUR_APPLIANCE_URL=$(cm CONJUR_APPLIANCE_URL)
CONJUR_ACCOUNT=$(cm CONJUR_ACCOUNT)
CONJUR_AUTHN_URL=$(cm CONJUR_AUTHN_URL)
CONJUR_AUTHENTICATOR_ID=$(cm CONJUR_AUTHENTICATOR_ID)
cm CONJUR_SSL_CERTIFICATE > "$WORK_DIR/conjur.pem"

echo "--- Generating webhook CA and serving certificate for $SERVICE_DNS"
cat > "$WORK_DIR/server.cnf" <<CNF
[req]
distinguished_name = dn
prompt = no
[dn]
CN = $SERVICE_DNS
[ext]
subjectAltName = DNS:conjur-injector,DNS:conjur-injector.${INJECTOR_NAMESPACE},DNS:${SERVICE_DNS},DNS:${SERVICE_DNS}.cluster.local
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
CNF
openssl req -x509 -newkey rsa:2048 -nodes -days "$CERT_DAYS" -subj "/CN=conjur-injector-ca" \
  -keyout "$WORK_DIR/ca.key" -out "$WORK_DIR/ca.crt" 2>/dev/null
openssl req -new -newkey rsa:2048 -nodes -config "$WORK_DIR/server.cnf" \
  -keyout "$WORK_DIR/tls.key" -out "$WORK_DIR/tls.csr" 2>/dev/null
openssl x509 -req -in "$WORK_DIR/tls.csr" -CA "$WORK_DIR/ca.crt" -CAkey "$WORK_DIR/ca.key" -CAcreateserial \
  -days "$CERT_DAYS" -extfile "$WORK_DIR/server.cnf" -extensions ext -out "$WORK_DIR/tls.crt" 2>/dev/null
if command -p base64 -w 0 /dev/null > /dev/null 2>&1; then
  CA_BUNDLE=$(base64 -w 0 < "$WORK_DIR/ca.crt")
else
  CA_BUNDLE=$(base64 -b 0 < "$WORK_DIR/ca.crt")
fi

echo "--- Deploying injector"
"$COP_CLI" apply -f "$SCRIPT_DIR/../manifests/01-injector.yml"
"$COP_CLI" create secret tls conjur-injector-tls -n "$INJECTOR_NAMESPACE" \
  --cert="$WORK_DIR/tls.crt" --key="$WORK_DIR/tls.key" --dry-run=client -o yaml | "$COP_CLI" apply -f -
"$COP_CLI" create configmap conjur-injector-config -n "$INJECTOR_NAMESPACE" \
  --from-literal=CONJUR_APPLIANCE_URL="$CONJUR_APPLIANCE_URL" \
  --from-literal=CONJUR_ACCOUNT="$CONJUR_ACCOUNT" \
  --from-literal=CONJUR_AUTHN_URL="$CONJUR_AUTHN_URL" \
  --from-literal=CONJUR_AUTHENTICATOR_ID="$CONJUR_AUTHENTICATOR_ID" \
  --from-literal=CONJUR_IDENTITY_PATH="$CONJUR_IDENTITY_PATH" \
  --from-literal=PROVIDER_IMAGE="$PROVIDER_IMAGE" \
  --from-literal=SUMMON_IMAGE="$SUMMON_IMAGE" \
  --from-literal=PROVIDER_RUN_AS_USER="$PROVIDER_RUN_AS_USER" \
  --from-file=CONJUR_SSL_CERTIFICATE="$WORK_DIR/conjur.pem" \
  --dry-run=client -o yaml | "$COP_CLI" apply -f -
"$COP_CLI" set image deployment/conjur-injector -n "$INJECTOR_NAMESPACE" injector="$INJECTOR_IMAGE"
"$COP_CLI" patch deployment conjur-injector -n "$INJECTOR_NAMESPACE" --type=json \
  -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/imagePullPolicy\",\"value\":\"$INJECTOR_PULL_POLICY\"}]"
# Pick up a new cert/config on re-runs
"$COP_CLI" rollout restart deployment/conjur-injector -n "$INJECTOR_NAMESPACE"
"$COP_CLI" rollout status deployment/conjur-injector -n "$INJECTOR_NAMESPACE" --timeout=120s

echo "--- Registering the mutating webhook (scope: $INJECT_SCOPE, failurePolicy: $FAILURE_POLICY)"
case "$INJECT_SCOPE" in
  labeled) WEBHOOK_MANIFEST=02-mutating-webhook.yml ;;
  all)     WEBHOOK_MANIFEST=02-mutating-webhook-all.yml ;;
  *) echo "INJECT_SCOPE must be labeled or all"; exit 1 ;;
esac
sed -e "s#\$CA_BUNDLE#${CA_BUNDLE}#" -e "s#\$FAILURE_POLICY#${FAILURE_POLICY}#" \
  "$SCRIPT_DIR/../manifests/$WEBHOOK_MANIFEST" | "$COP_CLI" apply -f -

if [ "$INJECT_SCOPE" = "all" ]; then
  echo "✅ Conjur injector is up for all namespaces. Pods opt in with the annotation conjur.org/inject: \"true\""
else
  echo "✅ Conjur injector is up. Opt a namespace in with: $COP_CLI label ns <name> conjur.org/injection=enabled"
fi
