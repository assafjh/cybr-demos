#!/bin/bash

# Pulls the latest demo WAR from GitHub Releases and deploys it to Tomcat.
# Falls back to a locally compiled artifact if the release is not reachable.

set -euo pipefail

# -- Variables --
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"
WEBAPPS_DIR="$TOMCAT_HOME/webapps"
LOCAL_BUILD_DIR="$SCRIPT_DIR/../code/demo-app/target"

RELEASE_TAG="ascp-demo-latest-build"
WAR_FILENAME="ascp-demo-app.war"
DEPLOY_NAME="ascp-demo-app.war"
RELEASE_URL="https://github.com/assafjh/cybr-demos/releases/download/${RELEASE_TAG}/${WAR_FILENAME}"

# -- Checks --
if [ ! -d "$WEBAPPS_DIR" ]; then
    echo "❌ Error: Tomcat webapps directory not found. Please run script 02 first."
    exit 1
fi

# -- Functions --
function download_from_release() {
    echo "🌐 Pulling latest artifact from GitHub Releases..."
    if curl -sSfL "$RELEASE_URL" -o "/tmp/$WAR_FILENAME"; then
        echo "✅ Download successful."
        return 0
    else
        echo "⚠️  Release artifact not reachable. Falling back to local build."
        return 1
    fi
}

function use_local_build() {
    local local_war
    local_war=$(find "$LOCAL_BUILD_DIR" -name "*.war" -print -quit 2>/dev/null || true)
    if [ -z "$local_war" ]; then
        echo "❌ Error: No local WAR found in $LOCAL_BUILD_DIR."
        echo "   Run optional-compile-demo.sh first to build locally."
        exit 1
    fi
    echo "📦 Using local build: $local_war"
    cp "$local_war" "/tmp/$WAR_FILENAME"
}

# -- Main --
if ! download_from_release; then
    use_local_build
fi

echo "🚀 Deploying $DEPLOY_NAME to Tomcat..."
cp "/tmp/$WAR_FILENAME" "$WEBAPPS_DIR/$DEPLOY_NAME"
rm -f "/tmp/$WAR_FILENAME"

echo "✅ Deployment complete. Start Tomcat with script 06, then open:"
echo "   http://localhost:8081/demo-app"
