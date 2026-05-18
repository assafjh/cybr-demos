#!/bin/bash
set -euo pipefail
[ -f ./conjur-lambda-package.zip ] && rm -f ./conjur-lambda-package.zip
[ -d ./package ] && rm -rf ./package
dnf install zip git -y
pip3 install -r requirements.txt --target ./package
cd ./package || exit
zip -r ../conjur-lambda-package.zip .
cd ..
zip conjur-lambda-package.zip lambda_function.py
