#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# -- Variables --
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"
APP_DIR="$SCRIPT_DIR/../code/demo-app"
WAR_NAME="demo-app.war"
WAR_LOCAL_PATH="$APP_DIR/target/$WAR_NAME"

# Update these to match your GitHub details
GITHUB_USER="assafjh"
GITHUB_REPO="cybr-demos"
GITHUB_BRANCH="ansible-awx-tower-playbooks" # או main
RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$GITHUB_BRANCH/application-server-credential-provider/compiled/$WAR_NAME"

# -- Functions --

function download_from_repo() {
    echo "🌐 Attempting to pull artifact from GitHub..."
    # ניסיון להוריד את הקובץ (במידה והחלטת לשמור עותק ב-compiled או ב-Releases)
    if curl -sSfL "$RAW_URL" -o "/tmp/$WAR_NAME"; then
        echo "✅ Successfully downloaded $WAR_NAME from GitHub."
        return 0
    else
        echo "⚠️  Could not download from GitHub (Check if URL exists or is private)."
        return 1
    fi
}

function build_locally() {
    if command -v mvn &> /dev/null; then
        echo "🛠️  Maven detected. Building application locally..."
        cd "$APP_DIR"
        mvn clean package -DskipTests[cite: 2]
        return 0
    else
        echo "❌ Maven not found. Cannot build locally."
        return 1
    fi
}

# -- Main Execution --

# 1. Verify Tomcat directory
if [ ! -d "$TOMCAT_HOME" ]; then
    echo "❌ Error: Tomcat directory not found. Please run script 02 first."
    exit 1
fi

echo "🚀 Starting deployment process..."

# 2. Try to find/get the WAR file
if [ -f "$WAR_LOCAL_PATH" ]; then
    echo "📦 Found local build at $WAR_LOCAL_PATH."
    DEPLOY_SOURCE="$WAR_LOCAL_PATH"
elif download_from_repo; then
    DEPLOY_SOURCE="/tmp/$WAR_NAME"
elif build_locally; then
    DEPLOY_SOURCE="$WAR_LOCAL_PATH"
else
    echo "❌ Error: Could not find, download, or build the application."
    exit 1
fi

# 3. Deploy to Tomcat
echo "🚚 Deploying $WAR_NAME to Tomcat webapps..."
cp "$DEPLOY_SOURCE" "$TOMCAT_HOME/webapps/"

echo "✨ Deployment successful!"
echo "🔗 Access the app: http://localhost:8081/demo-app"