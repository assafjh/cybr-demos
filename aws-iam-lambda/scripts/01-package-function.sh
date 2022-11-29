#!/bin/bash
[ -d ../function-source-code/package ] && rm -rf ../function-source-code/package
[ -f ../function-source-code/conjur-lambda-package.zip ] && rm -rf ../function-source-code/conjur-lambda-package.zip
pip install -r ../function-source-code/requirements.txt --target ../function-source-code/package
cd ../function-source-code/package || exit
zip -r ../conjur-lambda-package.zip .
cd ..
zip conjur-lambda-package.zip lambda_function.py conjur_iam_client.py