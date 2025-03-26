#!/bin/sh

ELASPED=0

while [ ! -s "$INJECTED_FILES_PATH/credentials.yaml" ] || [ ! -s "$INJECTED_FILES_PATH/credentials.properties" ]; do
  echo "[INFO] Waiting for Conjur secrets to be injected..."
  sleep 1
  ELASPED=$((ELASPED + 1))
  if [ "$ELASPED" -ge "$WAIT_TIMEOUT" ]; then
    echo "Timed out waiting for secrets. Exiting."
    exit 1
  fi
done

echo "======================"
echo "Files were injected by sidecar:"
ls -ltr "$INJECTED_FILES_PATH/"
echo "======================"
echo "printing $INJECTED_FILES_PATH/credentials.yaml"
cat "$INJECTED_FILES_PATH/credentials.properties"
echo ""
echo "======================"
echo "printing $INJECTED_FILES_PATH/credentials.properties"
cat "$INJECTED_FILES_PATH/credentials.properties"
if [ "$RUN_MESSENGER" = "true" ]; then
    echo ""
    echo "======================"
    echo "running $INJECTED_FILES_PATH/messenger"
    chmod +x "$INJECTED_FILES_PATH/messenger"
    "$INJECTED_FILES_PATH/messenger"
fi
sleep infinity
