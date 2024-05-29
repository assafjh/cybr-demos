#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "Java is not installed. Please install Java to proceed."
    exit 1
fi

# Check if javac is installed
if ! command -v javac &> /dev/null; then
    echo "javac is not installed. Please install the JDK to proceed."
    exit 1
fi

# Define the paths
CYBERARK_SDK_JAR="/opt/CARKaim/sdk/javapasswordsdk.jar"
JAVA_SOURCE_FOLDER="$SCRIPT_DIR/../code"
OUTPUT_JAR="$SCRIPT_DIR/../compiled/CyberArkCredentialProvider.jar"

# Compile the Java program
javac -cp .:"$CYBERARK_SDK_JAR" "$JAVA_SOURCE_FOLDER/CyberArkCredentialProvider.java"

# Create the JAR file
jar cfm "$OUTPUT_JAR $JAVA_SOURCE_FOLDER/manifest.txt" "CyberArkCredentialProvider.class"


echo "Compilation successful. JAR file created: $OUTPUT_JAR"
