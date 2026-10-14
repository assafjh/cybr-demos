#!/bin/bash
docker build -t aws-pub-lab:5443/summon-conjur-bin:test .
docker push aws-pub-lab:5443/summon-conjur-bin:test
