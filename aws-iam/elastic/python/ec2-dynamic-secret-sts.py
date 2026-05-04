# Install the required libraries
%pip3 install conjur-client --quiet
%pip3 install git+https://github.com/cyberark/conjur-authn-iam-client-python.git --quiet
%pip3 install boto3 --quiet

from os import environ, remove
import boto3
import json
from conjur import Client
from conjur_iam_client import create_conjur_iam_client_from_env

# Load environment variables
environ["CONJUR_APPLIANCE_URL"] = "https://<your-tenant>.secretsmgr.cyberark.cloud/api"
environ["AUTHN_IAM_SERVICE_ID"] = "demo"
environ["CONJUR_AUTHN_LOGIN"] = "host/data/aws/<your-account-id>/ajh-ec2-pub-lab-role"
environ["CONJUR_ACCOUNT"] = "conjur"

# Create Conjur client
conjur_client = create_conjur_iam_client_from_env()

# Fetch the STS token from Conjur
sts_token = json.loads(conjur_client.get("data/dynamic/aws-demo-s3-dynamic-secret").decode('utf-8'))

# Extract credentials from the nested 'data' field
access_key = sts_token["data"]["access_key_id"]
secret_key = sts_token["data"]["secret_access_key"]
session_token = sts_token["data"]["session_token"]

# Initialize an S3 client with the temporary credentials
s3_client = boto3.client(
    "s3",
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key,
    aws_session_token=session_token
)

# Specify the bucket name and object key to download
bucket_name = "ajh-conjur-demo"
object_key = "test.txt"

# Download the file
local_file_name = "/tmp/downloaded_test.txt"  # Use the /tmp directory in Databricks
s3_client.download_file(bucket_name, object_key, local_file_name)

print(f"Downloaded {object_key} from {bucket_name} to {local_file_name}")

# Process the file (e.g., read its contents)
with open(local_file_name, "r") as file:
    content = file.read()
    print(content)
    
remove(local_file_name)
print(f"Deleted {local_file_name}")
