from conjur import Client
from conjur_iam_client import create_conjur_iam_client_from_env
import os

def lambda_handler(event, context):
    # Retrieved from user-defined Lambda environment variables
    iam_role_name = os.environ['IAM_ROLE_NAME']
    # Retrieved from Lambda-defined runtime environment variables
    access_key = os.environ['AWS_ACCESS_KEY_ID']
    secret_key = os.environ['AWS_SECRET_ACCESS_KEY']
    token = os.environ['AWS_SESSION_TOKEN']
    # Set to false if self-signed or LetsEncrypt certificates are used
    ssl_verify=False
    
    # Use gathered token with env to request secret value
    conjur_client = create_conjur_iam_client_from_env(iam_role_name, access_key, secret_key, token, ssl_verify=ssl_verify)
    show_variable = conjur_client.get("aws/lambda/safe/secret2").decode('utf-8')
    return {
        "Secret2": show_variable
    }

# Change variable path to match that required within your Conjur instance
