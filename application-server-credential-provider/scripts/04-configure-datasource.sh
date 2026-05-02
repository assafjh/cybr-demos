#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# -- Variables --
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"
CONTEXT_XML="$TOMCAT_HOME/conf/context.xml"

# -- Postgres Driver (Aligned with pom.xml 42.7.3) --
POSTGRES_VERSION="42.7.3"
POSTGRES_JDBC_JAR="postgresql-${POSTGRES_VERSION}.jar"
POSTGRES_JDBC_URL="https://jdbc.postgresql.org/download/${POSTGRES_JDBC_JAR}"

# -- Database Connection Details --
POSTGRES_DB_HOST="localhost"
POSTGRES_DB_PORT=5433
POSTGRES_DB_NAME="vet"
POSTGRES_DB_USER="reception"
POSTGRES_DB_PASSWORD="vet_123456"

# -- CyberArk ASCP Configuration --
# Paths aligned with standard CyberArk CP Linux installation
CYBERARK_SDK_JAR="/opt/CARKaim/sdk/javapasswordsdk.jar"
CYBERARK_ASCP_JAR="/opt/CARKaim/sdk/javajdbc/CyberArk.jdbc.ASCPDriver.jar"

APP_ID="Zoo_App"
SAFE="App_Secrets"
OBJECT="Database_Account"
FOLDER="Root"

# Ensure Tomcat directory exists
if [ ! -d "$TOMCAT_HOME" ]; then
    echo "❌ Error: Tomcat directory not found. Please run script 02 first."
    exit 1
fi

# Download PostgreSQL JDBC Driver if not already present
if [ ! -f "$TOMCAT_HOME/lib/$POSTGRES_JDBC_JAR" ]; then
    echo "📥 Downloading PostgreSQL JDBC Driver v${POSTGRES_VERSION}..."
    wget -q "$POSTGRES_JDBC_URL" -O "/tmp/$POSTGRES_JDBC_JAR"
    cp "/tmp/$POSTGRES_JDBC_JAR" "$TOMCAT_HOME/lib/"
fi

# Link CyberArk JARs to Tomcat's lib directory
echo "🔗 Linking CyberArk SDK and ASCP Driver to Tomcat..."
if [ -f "$CYBERARK_ASCP_JAR" ] && [ -f "$CYBERARK_SDK_JAR" ]; then
    cp "$CYBERARK_ASCP_JAR" "$TOMCAT_HOME/lib/"
    cp "$CYBERARK_SDK_JAR" "$TOMCAT_HOME/lib/"
else
    echo "⚠️ Warning: CyberArk JARs not found. Ensure the Agent (Script 01) is installed."
fi

# Configure DataSources in context.xml
echo "📝 Configuring JNDI Resources in context.xml..."

# 1. Standard Postgres DataSource
if ! grep -q "jdbc/PostgresDS" "$CONTEXT_XML"; then
    echo "   Adding PostgresDS..."
    sed -i "/<\/Context>/i \
    <Resource name=\"jdbc/PostgresDS\" \
              auth=\"Container\" \
              type=\"javax.sql.DataSource\" \
              username=\"$POSTGRES_DB_USER\" \
              password=\"$POSTGRES_DB_PASSWORD\" \
              driverClassName=\"org.postgresql.Driver\" \
              url=\"jdbc:postgresql://$POSTGRES_DB_HOST:$POSTGRES_DB_PORT/$POSTGRES_DB_NAME\" \
              maxTotal=\"10\" />" "$CONTEXT_XML"
fi

# 2. CyberArk Managed DataSource (The ASCP "Magic")
if ! grep -q "jdbc/CyberArkDS" "$CONTEXT_XML"; then
    echo "   Adding CyberArkDS..."
    sed -i "/<\/Context>/i \
    <Resource name=\"jdbc/CyberArkDS\" \
              auth=\"Container\" \
              type=\"javax.sql.DataSource\" \
              driverClassName=\"com.cyberark.jdbc.ASCPDriver\" \
              url=\"jdbc:ascp:jdbc:postgresql://$POSTGRES_DB_HOST:$POSTGRES_DB_PORT/$POSTGRES_DB_NAME\" \
              username=\"dummy\" \
              password=\"dummy\" \
              connectionProperties=\"ascp_AppId=$APP_ID;ascp_Query=Safe=$SAFE,Folder=$FOLDER,Object=$OBJECT;ascp_VendorClass=org.postgresql.Driver;\" />" "$CONTEXT_XML"
fi

echo "✅ DataSource configuration complete."