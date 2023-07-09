#!/bin/sh
echo "======================"
echo "Using Service Account JWT - taken from file:"
ls -ltr /var/run/secrets/kubernetes.io/serviceaccount/token
echo "======================"
./retrieve.sh
sleep infinity
