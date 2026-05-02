# Conjur policies for TeamCity integration

This demo demonstrates how TeamCity builds can securely access secrets stored in CyberArk Conjur.

## Prerequisites
- Conjur Enterprise or OSS instance running.
- TeamCity server deployed.
- Conjur CLI configured.

## Instructions
1. Load the required policies into Conjur as depicted below.
2. Set up Conjur authentication in TeamCity build steps.
3. Run the TeamCity project to ensure secrets are fetched successfully.

The below diagram describes the organization we are loading into Conjur.
![Conjur policies for TeamCity integration](./teamcity-policies.png)
