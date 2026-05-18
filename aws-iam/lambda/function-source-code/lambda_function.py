from conjur_iam_client import create_conjur_iam_client_from_env
import os

def lambda_handler(event, context):
    # IAM_ROLE_NAME: user-defined Lambda environment variable
    iam_role_name = os.environ['IAM_ROLE_NAME']
    # AWS_ACCESS_KEY_ID / SECRET / SESSION_TOKEN: injected automatically by the Lambda runtime
    access_key = os.environ['AWS_ACCESS_KEY_ID']
    secret_key = os.environ['AWS_SECRET_ACCESS_KEY']
    token = os.environ['AWS_SESSION_TOKEN']
    ssl_verify = False

    conjur_client = create_conjur_iam_client_from_env(iam_role_name, access_key, secret_key, token, ssl_verify=ssl_verify)
    secret = conjur_client.get("data/aws/lambda/safe/secret2").decode('utf-8')
    return {
        "Secret2": secret
    }
