#!/bin/bash
set -uo pipefail

#============ Variables ===============
COP_CLI=kubectl
NAMESPACE=conjur-webhook-demo
APPS="${*:-demo-file-sidecar demo-file-init demo-k8s-secrets demo-summon demo-not-injected}"
#============ Script ===============

jp() { "$COP_CLI" get "$1" "$2" -n "$NAMESPACE" -o jsonpath="$3" 2>/dev/null; }

for app in $APPS; do
  POD=$("$COP_CLI" get pod -n "$NAMESPACE" -l app="$app" -o jsonpath='{.items[0].metadata.name}')
  echo "=================================================="
  TYPE=$(jp pod "$POD" '{.metadata.annotations.conjur\.org/inject-type}')
  if [ "$TYPE" = "summon" ]; then
    echo "  $app   (summon)"
  elif [ -n "$(jp pod "$POD" '{.metadata.annotations.conjur\.org/inject-status}')" ]; then
    echo "  $app   (secrets-provider: $(jp pod "$POD" '{.metadata.annotations.conjur\.org/secrets-destination}'), $(jp pod "$POD" '{.metadata.annotations.conjur\.org/container-mode}'))"
  else
    echo "  $app   (not injected)"
  fi
  echo "=================================================="
  echo "Deployment (what the app team wrote):"
  echo "  containers:      $(jp deploy "$app" '{.spec.template.spec.containers[*].name}')"
  echo "  initContainers:  $(jp deploy "$app" '{.spec.template.spec.initContainers[*].name}')"
  echo "  volumes:         $(jp deploy "$app" '{.spec.template.spec.volumes[*].name}')"
  echo "  command:         $(jp deploy "$app" '{.spec.template.spec.containers[0].command}')"
  echo "Running pod (after the injector):"
  echo "  containers:      $(jp pod "$POD" '{.spec.containers[*].name}')"
  echo "  initContainers:  $(jp pod "$POD" '{.spec.initContainers[*].name}')"
  echo "  volumes:         $(jp pod "$POD" '{.spec.volumes[*].name}')"
  echo "  command:         $(jp pod "$POD" '{.spec.containers[0].command}')"
  echo "  conjur identity: $(jp pod "$POD" '{.metadata.annotations.conjur\.org/inject-identity}')"
  if [ "$app" = "demo-k8s-secrets" ]; then
    echo "K8s Secret filled by the provider:"
    for k in secret4 secret8; do
      echo "  $k = $(jp secret webhook-demo-credentials "{.data.$k}" | base64 -d 2>/dev/null)"
    done
  fi
  echo "App log:"
  "$COP_CLI" logs "$POD" -n "$NAMESPACE" -c demo-application --tail=40 2>&1 | sed '/BEGIN CERTIFICATE/,/END CERTIFICATE/d' | sed 's/^/  /'
  echo
done
