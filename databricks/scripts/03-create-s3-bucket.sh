#!/bin/bash

# Create the bucket
aws s3 mb s3://ajh-conjur-demo

# Create the test.txt file
echo -e "a b c\n1 2 3\ntest" > test.txt

# Upload the file
aws s3 cp test.txt s3://ajh-conjur-demo/

# Verify upload
aws s3 ls s3://ajh-conjur-demo/

# Optional: Retrieve and check content
aws s3 cp s3://ajh-conjur-demo/test.txt downloaded_test.txt
cat downloaded_test.txt
