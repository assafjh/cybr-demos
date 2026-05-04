#!/bin/sh

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

echo "=========================================================="
echo " Starting Summon Demo App                                 "
echo " Secrets injected successfully via Summon-Conjur provider "
echo "=========================================================="
echo ""

./demo-consumer.sh

echo ""
echo "[INFO] Container is now sleeping. To test interactively, run:"
echo "       summon -p summon-conjur -f /scripts/secrets.yml /scripts/demo-consumer.sh"
exec sleep infinity
