#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_VERSION=${1:-"11.0.0-M20"}  # Default Tomcat version is 11.0.0-M20 if not specified
INSTALL_DIR="$SCRIPT_DIR/tomcat"
TOMCAT_PORT=${2:-8081}  # Default port is 8081 if not specified

# Functions

# Functions
function check_java_version() {
    if command -v java &> /dev/null; then
        JAVA_CURRENT_VERSION=$(java -version 2>&1 | awk -F[\".] 'NR==1{print $2}')
        echo "Detected Java version: $JAVA_CURRENT_VERSION"
        if [ "$JAVA_CURRENT_VERSION" -ge 17 ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

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

function download_tomcat() {
  local version=$1
  local major_version=$(echo $version | cut -d. -f1)
  local url="https://downloads.apache.org/tomcat/tomcat-$major_version/v$version/bin/apache-tomcat-$version.tar.gz"
  
  echo "Downloading Tomcat version $version from $url..."
  wget -q $url -O /tmp/apache-tomcat-$version.tar.gz
}

function install_tomcat() {
  local version=$1
  local install_dir=$2
  
  echo "Installing Tomcat..."
  mkdir -p $install_dir
  tar -xzf /tmp/apache-tomcat-$version.tar.gz -C $install_dir --strip-components=1
  chmod +x $install_dir/bin/*.sh
}

function configure_tomcat() {
  local install_dir=$1
  local port=$2

  echo "Configuring Tomcat to use port $port..."
  sed -i "s/port=\"8080\"/port=\"$port\"/" $install_dir/conf/server.xml
}

# Function to configure Tomcat users for admin access
configure_tomcat_users() {
  local install_dir=$1
  cat <<EOL > $install_dir/conf/tomcat-users.xml
<tomcat-users>
    <role rolename="manager-gui"/>
    <role rolename="admin-gui"/>
    <role rolename="manager-script"/>
    <user username="admin" password="password" roles="manager-gui,admin-gui,manager-script"/>
</tomcat-users>
EOL

  # Remove restrictions on IP addresses for accessing manager and host-manager
  sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' $install_dir/webapps/manager/META-INF/context.xml
  sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' $install_dir/webapps/host-manager/META-INF/context.xml

  sed -i '/<\/Context>/i \
<Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />' $install_dir/webapps/manager/META-INF/context.xml

  sed -i '/<\/Context>/i \
<Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />' $install_dir/webapps/host-manager/META-INF/context.xml
}

# Main script
if ! check_java_version; then
  echo "Java 17 or higher is required. Please install Java 17 or higher."
  exit 1
fi

download_tomcat $TOMCAT_VERSION
install_tomcat $TOMCAT_VERSION $INSTALL_DIR

# Set JAVA_HOME dynamically and configure Tomcat
set_java_home
configure_tomcat $INSTALL_DIR $TOMCAT_PORT
configure_tomcat_users $INSTALL_DIR

echo "Tomcat installation completed successfully."
echo "To start Tomcat, run ./06-start-tomcat.sh"

