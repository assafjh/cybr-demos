#!/bin/sh
echo "======================"
echo "Using Conjur Access Token - taken from Conjur authenticator client:"
ls -ltr /run/conjur/access-token
echo "======================"
./retrieve.sh
sleep infinity
