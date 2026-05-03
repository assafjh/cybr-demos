#!/bin/sh

echo "=========================================="
echo "🚀 App Container Started"
echo "🛠️ Environment Inspection (All Variables):"
echo "=========================================="
env
echo "=========================================="
echo "🔒 Filtered Secrets (ENV | grep SECRET):"
echo "=========================================="
env | grep SECRET || echo "[INFO] No environment variables containing 'SECRET' were found."
echo "=========================================="

echo "[INFO] Identity & Secrets demo container is running. Sleeping infinity..."
sleep infinity