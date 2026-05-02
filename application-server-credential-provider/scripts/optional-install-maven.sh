#!/bin/bash
set -e

MAVEN_VERSION=3.9.7
INSTALL_DIR=/opt/maven

if command -v mvn &> /dev/null; then
    echo "✅ Maven is already installed: $(mvn -version | head -n 1)"
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root" 
   exit 1
fi

echo "📥 Downloading Maven $MAVEN_VERSION..."
MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz"
wget -q "$MAVEN_URL" -O /tmp/maven.tar.gz

echo "🏗️  Installing Maven to $INSTALL_DIR..."
mkdir -p $INSTALL_DIR
tar -xzf /tmp/maven.tar.gz -C $INSTALL_DIR --strip-components=1
rm /tmp/maven.tar.gz

# Link to bin for immediate availability
ln -sf $INSTALL_DIR/bin/mvn /usr/bin/mvn

echo "📝 Setting up environment variables..."
cat <<EOL > /etc/profile.d/maven.sh
export MAVEN_HOME=$INSTALL_DIR
export PATH=\$MAVEN_HOME/bin:\$PATH
EOL

echo "✅ Maven installation completed: $(mvn -version | head -n 1)"