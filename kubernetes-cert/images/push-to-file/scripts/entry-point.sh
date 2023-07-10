#!/bin/sh
sleep 1
echo "======================"
echo "Files were injected by sidecar:"
ls -ltr "$INJECTED_FILES_PATH/"
echo "======================"
echo "printing $INJECTED_FILES_PATH/credentials.yaml"
cat "$INJECTED_FILES_PATH/credentials.properties"
echo "======================"
echo "printing $INJECTED_FILES_PATH/credentials.properties"
cat "$INJECTED_FILES_PATH/credentials.properties"
echo "======================"
echo "running $INJECTED_FILES_PATH/messenger"
chmod +x "$INJECTED_FILES_PATH/messenger"
"$INJECTED_FILES_PATH/messenger"
sleep infinity
