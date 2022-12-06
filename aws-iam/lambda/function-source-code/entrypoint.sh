#!/bin/bash
[ -f ./conjur-lambda-package.zip ] && rm -rf ./conjur-lambda-package.zip
[ -d ./package ] && rm -rf ./package
yum install zip -y
pip3 install -r requirements.txt --target ./package
cd ./package || exit
zip -r ../conjur-lambda-package.zip .
cd ..
zip conjur-lambda-package.zip lambda_function.py conjur_iam_client.py
