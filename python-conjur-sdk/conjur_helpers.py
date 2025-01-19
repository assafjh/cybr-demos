import os
from dotenv import load_dotenv
from conjur_api import Client
from conjur_api.models import ConjurConnectionInfo, SslVerificationMode, SslVerificationMetadata
from conjur_api.providers.authn_authentication_strategy import AuthnAuthenticationStrategy
from conjur_api.providers import SimpleCredentialsProvider
from conjur_api.models import CredentialsData

# Load environment variables
load_dotenv()

class ConjurHelper:
    def __init__(self, ssl_verification_mode=SslVerificationMode.TRUST_STORE, cert_file=None):
        """
        Initialize the helper with connection info and credentials from the .env file.
        SSL configuration is either provided as parameters or loaded from the environment.
        """
        # Load settings from environment
        self.conjur_url = os.getenv("CONJUR_URL")
        self.conjur_account = os.getenv("CONJUR_ACCOUNT", "conjur")  # Default to "conjur" if not provided
        self.username = os.getenv("CONJUR_HOST")
        self.api_key = os.getenv("CONJUR_API_KEY")
        self.cert_file = cert_file or os.getenv("CONJUR_CERT_FILE")

        if not all([self.conjur_url, self.username, self.api_key]):
            raise ValueError("Missing required environment variables in .env file")

        # Determine SSL verification mode, defaulting to TRUST_STORE
        self.ssl_verification_mode = (
            ssl_verification_mode or 
            SslVerificationMode[os.getenv("CONJUR_SSL_MODE", "TRUST_STORE").upper()]
        )

        # Setup Conjur connection info
        self.connection_info = ConjurConnectionInfo(
            conjur_url=self.conjur_url,
            account=self.conjur_account,
            cert_file=self.cert_file  # Optional certificate file for SSL
        )

        # Initialize credentials and strategy
        self.credentials = CredentialsData(
            username=self.username,
            api_key=self.api_key,
            machine=self.conjur_url  # Ensure the machine matches the Conjur URL
        )
        self.credentials_provider = SimpleCredentialsProvider()
        self.credentials_provider.save(self.credentials)
        self.authn_strategy = AuthnAuthenticationStrategy(self.credentials_provider)

        # Store SSL verification metadata
        self.ssl_metadata = SslVerificationMetadata(
            mode=self.ssl_verification_mode,
            ca_cert_path=self.cert_file
        )

        # Create the Conjur client
        self.client = Client(
            connection_info=self.connection_info,
            authn_strategy=self.authn_strategy,
            ssl_verification_mode=self.ssl_verification_mode
        )

    async def authenticate_host_api_key(self):
        """
        Authenticate using API key and return the token.
        """
        print(f"Authenticating as {self.username}...")
        token, expiration = await self.authn_strategy.authenticate(
            connection_info=self.connection_info,
            ssl_verification_data=self.ssl_metadata
        )
        print(f"Authenticated successfully. Token expires at: {expiration}")
        return token

    async def get_secret(self, secret_id):
        """
        Fetch a secret from Conjur.
        """
        try:
            print(f"Fetching secret: {secret_id}")
            secret = await self.client.get(secret_id)  # Correct method for fetching the secret
            return secret.decode('utf-8')
        except Exception as e:
            raise RuntimeError(f"Failed to fetch secret: {e}")
