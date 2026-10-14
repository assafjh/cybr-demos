#!/bin/bash
set -e

docker build --no-cache --pull -t aws-pub-lab:5443/conjur-injector:test .

docker push aws-pub-lab:5443/conjur-injector:test
