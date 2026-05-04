#!/bin/sh

echo "[demo-consumer.sh] Application process started."
echo "[demo-consumer.sh] Reading injected environment variables based on /scripts/secrets.yml..."
echo ""

if [ ! -f "/scripts/secrets.yml" ]; then
  echo "❌ ERROR: /scripts/secrets.yml is missing!"
  exit 1
fi

# Dynamically extract keys from whatever secrets.yml is mounted
KEYS=$(grep -E '^[A-Za-z0-9_]+:' /scripts/secrets.yml | cut -d: -f1)

MISSING=0
echo "📋 Extracted Values:"

for KEY in $KEYS; do
  VAL=$(printenv "$KEY")
  if [ -z "$VAL" ]; then
    echo "   ❌ $KEY: [MISSING - Summon failed to inject]"
    MISSING=1
  else
    echo "   🔑 $KEY: $VAL"
  fi
done

echo ""
if [ $MISSING -eq 1 ]; then
  echo "❌ ERROR: One or more requested secrets were not found in the environment."
  exit 1
fi

echo "✅ Success! All requested secrets exist securely in the process memory."
echo "⚠️  WARNING: This is a DEMO. Never print real secrets to stdout in production!"
