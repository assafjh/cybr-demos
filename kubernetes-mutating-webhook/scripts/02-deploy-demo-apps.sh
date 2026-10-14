#!/bin/bash
set -euo pipefail

#============ Variables ===============
COP_CLI=kubectl
NAMESPACE=conjur-webhook-demo
APPS="demo-file-sidecar demo-file-init demo-k8s-secrets demo-summon demo-not-injected"
#============ Script ===============

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

"$COP_CLI" apply -f "$SCRIPT_DIR/../manifests/03-demo-apps.yml"
for d in $APPS; do
  "$COP_CLI" rollout status deployment/"$d" -n "$NAMESPACE" --timeout=180s
done
echo "✅ Demo apps deployed. Run scripts/03-show-injection.sh"
