#!/bin/bash
set -euo pipefail
cd ../function-source-code || exit
docker run --rm -v "$PWD":/var/task --entrypoint /bin/bash amazon/aws-lambda-python:3.12 /var/task/entrypoint.sh
