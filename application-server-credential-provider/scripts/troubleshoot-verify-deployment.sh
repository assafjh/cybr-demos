#!/bin/bash

# Define Tomcat and application directories
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"
APP_DIR="$TOMCAT_HOME/webapps/demo-app"

# Check if web.xml exists
if [ -f "$APP_DIR/WEB-INF/web.xml" ]; then
    echo "web.xml found in WEB-INF directory."
else
    echo "web.xml not found in WEB-INF directory."
    exit 1
fi

# Check if ZooServlet.class exists
if [ -f "$APP_DIR/WEB-INF/classes/com/example/ZooServlet.class" ]; then
    echo "ZooServlet.class found in WEB-INF/classes/com/example directory."
else
    echo "ZooServlet.class not found in WEB-INF/classes/com/example directory."
    exit 1
fi

echo "All files in place. Ready to deploy."

