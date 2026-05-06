#!/bin/bash
set -euo pipefail

# Default to Java 17 as required for our Jakarta Servlet
JAVA_VERSION=${1:-17}

function check_java_version() {
    if command -v java &> /dev/null; then
        # More robust version parsing
        JAVA_CURRENT_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_CURRENT_VERSION" -ge "$JAVA_VERSION" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

if check_java_version; then
    echo "✅ Java $JAVA_VERSION or higher is already installed."
    exit 0
fi

echo "📦 Installing OpenJDK $JAVA_VERSION Development Kit..."
sudo yum install -y "java-${JAVA_VERSION}-openjdk-devel"

sudo alternatives --set java "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk/bin/java"
sudo alternatives --set javac "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk/bin/javac"

echo "export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::')" | sudo tee /etc/profile.d/jdk_home.sh
# Re-login or run: source /etc/profile.d/jdk_home.sh

echo "✨ JDK installation successful. Current version:"
java -version