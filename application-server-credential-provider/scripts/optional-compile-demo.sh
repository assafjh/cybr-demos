#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# -- Variables --
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
APP_DIR="$SCRIPT_DIR/../code/demo-app"

# -- Prerequisites Check --

echo "🔍 Checking for build tools..."

# Check Java version (Must be 17+ for Jakarta EE)
if command -v java &> /dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VER" -lt 17 ]; then
        echo "❌ Error: Java 17 or higher is required. Found version $JAVA_VER."
        exit 1
    fi
else
    echo "❌ Error: Java is not installed. Please run optional-install-java.sh."
    exit 1
fi

# Check Maven
if ! command -v mvn &> /dev/null; then
    echo "❌ Error: Maven is not installed. Please run optional-install-maven.sh."
    exit 1
fi

# -- Compilation Process --

echo "🛠️  Starting local compilation of 'demo-app'..."

# Navigate to application directory
cd "$APP_DIR"

# Execute Maven build
# clean: Removes old build artifacts
# package: Compiles, tests, and creates the WAR file
# -DskipTests: Skips unit tests to speed up local demo builds
mvn clean package -DskipTests

# -- Success Verification --

WAR_FILE=$(find target/ -name "*.war" -print -quit)

if [ -f "$WAR_FILE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ SUCCESS: Application compiled successfully!"
    echo "📦 Artifact: $WAR_FILE"
    echo "📅 Date: $(date)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "❌ Error: Build finished but WAR file was not found."
    exit 1
fi