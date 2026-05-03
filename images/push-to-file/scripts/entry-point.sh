#!/bin/sh

ELAPSED=0

echo "[INFO] Starting App Container - Waiting for Conjur Secrets Provider..."

while [ ! -s "$INJECTED_FILES_PATH/credentials.yaml" ] || [ ! -s "$INJECTED_FILES_PATH/credentials.properties" ]; do
  sleep 1
  ELAPSED=$((ELAPSED + 1))
  if [ "$ELAPSED" -ge "$WAIT_TIMEOUT" ]; then
    echo "[ERROR] Timed out ($WAIT_TIMEOUT sec) waiting for secrets. Exiting."
    exit 1
  fi
done

echo "=========================================="
echo "✅ Secrets successfully injected by Sidecar:"
ls -ltr "$INJECTED_FILES_PATH/"
echo "=========================================="

echo ""
echo "[CONTENT] -> $INJECTED_FILES_PATH/credentials.yaml"
cat "$INJECTED_FILES_PATH/credentials.yaml"

echo ""
echo "[CONTENT] -> $INJECTED_FILES_PATH/credentials.properties"
cat "$INJECTED_FILES_PATH/credentials.properties"
echo "=========================================="

if [ "$RUN_MESSENGER" = "true" ]; then
    echo ""
    echo "[INFO] Running Messenger App: $INJECTED_FILES_PATH/messenger"
    chmod +x "$INJECTED_FILES_PATH/messenger"
    "$INJECTED_FILES_PATH/messenger"
fi

echo "[INFO] App initialization complete. Sleeping infinity..."
sleep infinity