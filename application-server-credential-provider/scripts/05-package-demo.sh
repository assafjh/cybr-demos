#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"

# Function to dynamically find and set JAVA_HOME for Java 17 and above
set_java_home() {
  if [ -d /usr/lib/jvm ]; then
    JAVA_HOME=$(find /usr/lib/jvm -maxdepth 1 -type d \( -name "java-*-openjdk*" -o -name "jdk-*" \) | while read dir; do
      version=$(echo "$dir" | grep -oP "\d+" | head -1)
      if [ "$version" -ge 17 ]; then
        echo "$dir"
        break
      fi
    done)
    if [ -z "$JAVA_HOME" ]; then
      echo "No suitable JDK found in /usr/lib/jvm. Please install OpenJDK 17 or higher."
      exit 1
    fi
  else
    echo "/usr/lib/jvm directory does not exist. Please install OpenJDK 17 or higher."
    exit 1
  fi
}

set_java_home
export PATH=$JAVA_HOME/bin:$PATH:/opt/maven/bin

# Check if jar is installed
if ! command -v mvn &> /dev/null; then
    echo "mvn is not installed. Please install Maven to proceed."
    exit 1
fi

# Create the WAR file
cd "$SCRIPT_DIR/../code/demo-app"
mvn clean compile
mvn package

# Deploy WAR
cp target/demo-app.war $TOMCAT_HOME/webapps/

echo "Deployment completed successfully. The application has been deployed to Tomcat."

