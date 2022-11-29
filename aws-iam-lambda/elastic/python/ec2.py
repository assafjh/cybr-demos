#!/usr/bin/python3
from conjur import Client
from conjur_iam_client import create_conjur_iam_client_from_env

conjur_client = create_conjur_iam_client_from_env()
show_variable = conjur_client.get("aws/elastic/safe/secret3").decode('utf-8')
print("Secret3: " + show_variable)


