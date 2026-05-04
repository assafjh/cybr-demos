# GCP Onboarding
Select New GCP organization!

# Login to gcloud
gcloud config set account <your-email@example.com>
gcloud auth login

# Set project
gcloud projects list
gcloud config set project PROJECT_ID
gcloud config get-value project

# GET CEM deployment script
curl --request GET \
  --url https://<your-cem-tenant>.cyberark.cloud/api/new_account/get-deployment-script \
  --header 'accept: application/json, text/plain, */*'
  --header 'Authorization: Bearer <authorization-parameters>'

# Download and unzip
rm -rf gcp-deployment-mgr
curl '<Download-URL>' -o gcp-deployment-mgr.zip
unzip gcp-deployment-mgr.zip -d gcp-deployment-mgr && cd gcp-deployment-mgr

# Run deployment script
./deploy.sh -p <PROJECT_ID>
## Run on current project
./deploy.sh -p $(gcloud projects list --format="value(projectId)")

# Create App engine if needed
gcloud app create --region=europe-west

# Extarct final value
python3 get-final-value-gcp.py --help
python3 get-final-value-gcp.py

# Onboard the project
For some reason extracting key and data from the SA json key is different - prob it goes through some maniplulation.
Just connect to CEM through the UI.

#