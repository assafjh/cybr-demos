# Install the required libraries
%pip install python-dotenv --quiet
%pip install conjur-api==0.1.2 --ignore-requires-python --quiet
%pip install nest_asyncio --quiet

import os
import asyncio
from dotenv import load_dotenv
from conjur_api import Client
from conjur_api.models import ConjurConnectionInfo, SslVerificationMode, SslVerificationMetadata
from conjur_api.providers.authn_authentication_strategy import AuthnAuthenticationStrategy
from conjur_api.providers import SimpleCredentialsProvider
from conjur_api.models import CredentialsData
import asyncio
import nest_asyncio

# Load environment variables
os.environ["CONJUR_URL"] = "https://<tenant>.secretsmgr.cyberark.cloud/api"
os.environ["CONJUR_HOST"] = "host/data/python/demo-app-host"
os.environ["CONJUR_API_KEY"] = "<API_KEY>"

class ConjurHelper:
    def __init__(self, ssl_verification_mode=SslVerificationMode.TRUST_STORE, cert_file=None):
        self.conjur_url = os.getenv("CONJUR_URL")
        self.conjur_account = os.getenv("CONJUR_ACCOUNT", "conjur")
        self.username = os.getenv("CONJUR_HOST")
        self.api_key = os.getenv("CONJUR_API_KEY")
        self.cert_file = cert_file or os.getenv("CONJUR_CERT_FILE")

        if not all([self.conjur_url, self.username, self.api_key]):
            raise ValueError("Missing required environment variables")

        self.ssl_verification_mode = ssl_verification_mode
        self.connection_info = ConjurConnectionInfo(
            conjur_url=self.conjur_url,
            account=self.conjur_account,
            cert_file=self.cert_file
        )

        self.credentials = CredentialsData(
            username=self.username,
            api_key=self.api_key,
            machine=self.conjur_url
        )
        self.credentials_provider = SimpleCredentialsProvider()
        self.credentials_provider.save(self.credentials)
        self.authn_strategy = AuthnAuthenticationStrategy(self.credentials_provider)
        self.ssl_metadata = SslVerificationMetadata(
            mode=self.ssl_verification_mode,
            ca_cert_path=self.cert_file
        )
        self.client = Client(
            connection_info=self.connection_info,
            authn_strategy=self.authn_strategy,
            ssl_verification_mode=self.ssl_verification_mode
        )

    async def authenticate(self):
        print(f"Authenticating as {self.username}...")
        token, expiration = await self.authn_strategy.authenticate(
            connection_info=self.connection_info,
            ssl_verification_data=self.ssl_metadata
        )
        print(f"Authenticated successfully. Token expires at: {expiration}")
        return token

    async def get_secret(self, secret_id):
        try:
            print(f"Fetching secret: {secret_id}")
            secret = await self.client.get(secret_id)
            return secret.decode('utf-8')
        except Exception as e:
            raise RuntimeError(f"Failed to fetch secret: {e}")

# Main Execution Block
nest_asyncio.apply()

async def main():
    helper = ConjurHelper()
    await helper.authenticate()
    secret_id = "data/vault/Conjur-Springboot-Dev/secret1/password"  # Update with your secret path
    secret = await helper.get_secret(secret_id)
    print(f"Fetched secret: {secret}")

asyncio.get_event_loop().run_until_complete(main())
