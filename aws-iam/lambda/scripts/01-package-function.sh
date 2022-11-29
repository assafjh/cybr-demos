#!/bin/bash
cd ../function-source-code
docker run -it --rm -v "$PWD":/var/task --entrypoint /bin/bash amazon/aws-lambda-python:latest /var/task/entrypoint.sh
