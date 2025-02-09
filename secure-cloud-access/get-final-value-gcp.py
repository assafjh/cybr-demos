import subprocess
import requests
import json
import argparse
import re

def get_access_token():
    """Get the access token using gcloud command."""
    try:
        result = subprocess.run(['gcloud', 'auth', 'print-access-token'], stdout=subprocess.PIPE, check=True)
        return result.stdout.decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        print(f"Error obtaining access token: {e}")
        return None

def get_current_project_id():
    """Get the current project ID from gcloud configuration."""
    try:
        result = subprocess.run(['gcloud', 'config', 'get-value', 'project'], stdout=subprocess.PIPE, check=True)
        return result.stdout.decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        print(f"Error obtaining current project ID: {e}")
        return None

def get_deployment_manifest(project_id, deployment_name):
    """Get the deployment manifest from Deployment Manager."""
    access_token = get_access_token()
    if not access_token:
        return None

    url = f"https://www.googleapis.com/deploymentmanager/v2/projects/{project_id}/global/deployments/{deployment_name}"
    headers = {
        'Authorization': f'Bearer {access_token}'
    }

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        deployment_details = response.json()
        manifest_url = deployment_details.get('manifest')

        if manifest_url:
            manifest_response = requests.get(manifest_url, headers=headers)
            if manifest_response.status_code == 200:
                return manifest_response.json()
            else:
                print(f"Error: {manifest_response.status_code} - {manifest_response.text}")
                return None
        else:
            print("Error: Manifest URL not found in deployment details")
            return None
    else:
        print(f"Error: {response.status_code} - {response.text}")
        return None

def extract_final_value_from_text(manifest_json, final_value_key):
    """Extract the finalValue from the JSON manifest using text search."""
    try:
        layout_str = manifest_json.get('layout')
        if layout_str:
            match = re.search(rf'{final_value_key}:\s*(.*)', layout_str)
            if match:
                return match.group(1).strip()
        print(f"Error: '{final_value_key}' not found in the manifest content")
        return None
    except KeyError as e:
        print(f"Error accessing {final_value_key}: {e}")
        return None

def main():
    """Main function to get configuration from user and display finalValue."""
    parser = argparse.ArgumentParser(description="Retrieve finalValue from Google Cloud Deployment Manager")
    parser.add_argument('--project_id', default=get_current_project_id(), help="Google Cloud project ID (default: current gcloud project)")
    parser.add_argument('--deployment_name', default='cem-service-account', help="Deployment name (default: 'cem-service-account')")
    parser.add_argument('--final_value_key', default='finalValue', help="Key of the final value to retrieve (default: 'finalValue')")

    args = parser.parse_args()

    project_id = args.project_id
    deployment_name = args.deployment_name
    final_value_key = args.final_value_key

    manifest_json = get_deployment_manifest(project_id, deployment_name)
    if manifest_json:
        final_value = extract_final_value_from_text(manifest_json, final_value_key)
        if final_value:
            print(f"{final_value_key}: {final_value}")
        else:
            # Print the manifest content to inspect the structure if final value not found
            print(json.dumps(manifest_json, indent=2))

if __name__ == "__main__":
    main()
