#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# -- Variables --
# -- Tomcat --
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"
CONTEXT_XML="$TOMCAT_HOME/conf/context.xml"
# -- Postgres --
POSTGRES_JDBC_URL="https://jdbc.postgresql.org/download/postgresql-42.2.24.jar"
POSTGRES_JDBC_JAR="postgresql-42.2.24.jar"
POSTGRES_DB_HOST=$(hostname)
POSTGRES_DB_PORT=5433
POSTGRES_DB_NAME=vet
POSTGRES_DB_USER=reception
POSTGRES_DB_PASSWORD=vet_123456
# -- Credential Provider --
CYBERARK_JDBC_JAR="/opt/CARKaim/sdk/javapasswordsdk.jar"
APP_ID=AIMWebService
SAFE=Demo-Safe-General
OBJECT=Database-PostgreSQL-reception
FOLDER=Root
REASON=Demo

# Ensure the script is run as root or with sudo if needed
SUDO=

# Download PostgreSQL JDBC Driver
echo "Downloading PostgreSQL JDBC Driver..."
wget -q $POSTGRES_JDBC_URL -O /tmp/$POSTGRES_JDBC_JAR

# Copy PostgreSQL JDBC Driver to Tomcat's lib directory
echo "Copying PostgreSQL JDBC Driver to Tomcat's lib directory..."
$SUDO cp /tmp/$POSTGRES_JDBC_JAR $TOMCAT_HOME/lib/

# Copy CyberArk JDBC Driver to Tomcat's lib directory
echo "Copying CyberArk JDBC Driver to Tomcat's lib directory..."
$SUDO cp $CYBERARK_JDBC_JAR $TOMCAT_HOME/lib/

# Configure DataSource in context.xml
echo "Configuring DataSource in context.xml..."
if grep -q "<Resource name=\"jdbc/PostgresDS\"" "$CONTEXT_XML"; then
    echo "Postgres DataSource already configured in context.xml"
else
    $SUDO sed -i "/<\/Context>/i \
    <Resource name=\"jdbc/PostgresDS\" \
              auth=\"Container\" \
              type=\"javax.sql.DataSource\" \
              username=\"$POSTGRES_DB_USER\" \
              password=\"$POSTGRES_DB_PASSWORD\" \
              driverClassName=\"org.postgresql.Driver\" \
              url=\"jdbc:postgresql://$POSTGRES_DB_HOST:$POSTGRES_DB_PORT/$POSTGRES_DB_NAME\" \
              maxTotal=\"20\" \
              maxIdle=\"10\" \
              maxWaitMillis=\"-1\"/>" "$CONTEXT_XML"
    echo "Postgres DataSource configuration added to context.xml"
fi

if grep -q "<Resource name=\"jdbc/CyberArkDS\"" "$CONTEXT_XML"; then
    echo "CyberArk DataSource already configured in context.xml"
else
    $SUDO sed -i "/<\/Context>/i \
    <Resource name=\"jdbc/CyberArkDS\" \
          auth=\"Container\" \
          type=\"javax.sql.DataSource\" \
          driverClassName=\"com.cyberark.jdbc.ASCPDriver\" \
          url=\"jdbc:ascp:jdbc:postgresql://$POSTGRES_DB_HOST:$POSTGRES_DB_PORT/$POSTGRES_DB_NAME\" \
          username=\"dummy\" \
          password=\"dummy\" \
          connectionProperties=\"ascp_AppId=$APP_ID; \
                               ascp_Query=Safe=$SAFE,Folder=$FOLDER,Object=$OBJECT,Reason=$REASON; \
                               ascp_VendorClass=org.postgresql.Driver; \
                               ssl=true\"/>" "$CONTEXT_XML"
    echo "CyberArk DataSource configuration added to context.xml"
fi

echo "PostgreSQL and CyberArk DataSource installation completed."

