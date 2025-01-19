import asyncio
import nest_asyncio
from conjur_helpers import ConjurHelper

# Initialize the helper
helper = ConjurHelper()

# Main Execution Block
nest_asyncio.apply()

async def main():
    helper = ConjurHelper()
    await helper.authenticate_host_api_key()
    secret_id = "data/vault/Conjur-Python-SDK/secret1/password"  # Update with your secret path
    secret = await helper.get_secret(secret_id)
    print(f"Fetched secret: {secret}")

asyncio.get_event_loop().run_until_complete(main())
