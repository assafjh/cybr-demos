#!/bin/bash
# This script is meant for containerized Jenkins, if this is not the case - copy and use the keytool command from below.
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=podman
# Conjur FQDN and port without scheme
CONJUR_HOST_AND_PORT="$(hostname)":443
# Jenkins container ID
JENKINS_CONTAINER_ID=$(podman ps -a --filter "name=.*jenkins.*" --format "{{.ID}}")
#========== Functions ===============
COMPARE_VERSION() {
    if [[ $1 == [[$2]] ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
function SET_CACERTS_PATH() {
	CACERTS="-storetype JKS -keystore $JAVA_HOME/jre/lib/security/cacerts"
	JAVA_VERSION=$($SUDO $CONTAINER_MGR exec -it "$JENKINS_CONTAINER_ID" java -version 2>&1 | awk -F '"' '{print $2}')
	COMPARE_VERSION "$JAVA_VERSION" "1.9"
	if [[ $? -eq 1 ]]; then
		CACERTS="-cacerts"
	fi
}
#============ Script ===============
if [[ ! -f "$HOME/conjur-server.pem" ]]; then 
    openssl s_client -showcerts -connect "$CONJUR_HOST_AND_PORT" < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$HOME/conjur-server.pem"
fi
$CONTAINER_MGR cp "$HOME/conjur-server.pem" "$JENKINS_CONTAINER_ID":/tmp
SET_CACERTS_PATH
$CONTAINER_MGR exec --user=0 -it "$JENKINS_CONTAINER_ID" keytool -import -alias conjur_pub_key -file /tmp/conjur-server.pem ${CACERTS} -storepass changeit -noprompt
