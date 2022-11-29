#!/bin/bash
cd ../function-source-code
docker run -it --rm -v "$PWD":/var/task lambci/lambda:build-python3.8 /bin/bash -c /var/task/entrypoint.sh
