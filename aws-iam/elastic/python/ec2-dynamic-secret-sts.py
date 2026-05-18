# Install dependencies (see requirements.txt / pyproject.toml for pinned versions)
%pip install conjur boto3 git+https://github.com/cyberark/conjur-authn-iam-client-python.git --quiet

from os import environ, remove
import boto3
import json
from conjur_iam_client import create_conjur_iam_client_from_env

# Load environment variables
environ["CONJUR_APPLIANCE_URL"] = "https://<your-tenant>.secretsmgr.cyberark.cloud/api"
environ["AUTHN_IAM_SERVICE_ID"] = "demo"
environ["CONJUR_AUTHN_LOGIN"] = "host/data/aws/<your-aws-account-id>/<your-iam-role-name>"
environ["CONJUR_ACCOUNT"] = "conjur"

# Create Conjur client using the EC2 instance's IAM role credentials
conjur_client = create_conjur_iam_client_from_env()

# Fetch dynamic STS credentials from Conjur
sts_token = json.loads(conjur_client.get("data/dynamic/<your-dynamic-secret-path>").decode('utf-8'))

# Extract temporary AWS credentials
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
bucket_name = "<your-s3-bucket-name>"
object_key = "test.txt"

# Download the file
local_file_name = "/tmp/downloaded_test.txt"
s3_client.download_file(bucket_name, object_key, local_file_name)

print(f"Downloaded {object_key} from {bucket_name} to {local_file_name}")

with open(local_file_name, "r") as file:
    content = file.read()
    print(content)

remove(local_file_name)
print(f"Deleted {local_file_name}")
