#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"
POSTGRES_JDBC_URL="https://jdbc.postgresql.org/download/postgresql-42.2.24.jar"
POSTGRES_JDBC_JAR="postgresql-42.2.24.jar"
CONTEXT_XML="$TOMCAT_HOME/conf/context.xml"
DB_HOST=$(hostname)

# Ensure the script is run as root or with sudo if needed
SUDO=

# Download PostgreSQL JDBC Driver
echo "Downloading PostgreSQL JDBC Driver..."
wget -q $POSTGRES_JDBC_URL -O /tmp/$POSTGRES_JDBC_JAR

# Copy PostgreSQL JDBC Driver to Tomcat's lib directory
echo "Copying PostgreSQL JDBC Driver to Tomcat's lib directory..."
$SUDO cp /tmp/$POSTGRES_JDBC_JAR $TOMCAT_HOME/lib/

# Configure DataSource in context.xml
echo "Configuring DataSource in context.xml..."
if grep -q "<Resource name=\"jdbc/PostgresDS\"" "$CONTEXT_XML"; then
    echo "DataSource already configured in context.xml"
else
    $SUDO sed -i "/<\/Context>/i \
    <Resource name=\"jdbc/PostgresDS\" \
              auth=\"Container\" \
              type=\"javax.sql.DataSource\" \
              username=\"reception\" \
              password=\"vet_123456\" \
              driverClassName=\"org.postgresql.Driver\" \
              url=\"jdbc:postgresql://$DB_HOST:5432/vet\" \
              maxActive=\"20\" \
              maxIdle=\"10\" \
              maxWait=\"-1\"/>" "$CONTEXT_XML"
    echo "DataSource configuration added to context.xml"
fi

echo "PostgreSQL DataSource installation completed."

