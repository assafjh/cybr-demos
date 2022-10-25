#!/bin/bash
#============ Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/conjur_env.properties
source $SCRIPT_DIR/scripts.properties
#========== Functions ===============
COMPARE_VERSION() {
    if [[ $1 == $2 ]]
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
	JAVA_VERSION=$($CONTAINER_MGR exec -it "$JENKINS_CONTAINER_ID" java -version 2>&1 | awk -F '"' '{print $2}')
	COMPARE_VERSION "$JAVA_VERSION" "1.9"
	if [[ $? -eq 1 ]]; then
		CACERTS="-cacerts"
	fi
}
#--------------- Script ------------
[ ! -d "$SCRIPT_DIR/certs" ] && mkdir $SCRIPT_DIR/certs
echo "Saving Conjur public key in base64 encoded DER format: $SCRIPT_DIR/certs/conjur-public-key.pem"
openssl s_client -showcerts -connect $HOSTNAME:443 < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$SCRIPT_DIR"/certs/conjur-public-key.pem
$CONTAINER_MGR cp "$SCRIPT_DIR"/certs/conjur-public-key.pem "$JENKINS_CONTAINER_ID":/tmp
SET_CACERTS_PATH
$CONTAINER_MGR exec --user=0 -it "$JENKINS_CONTAINER_ID" keytool -import -alias conjur_pub_key -file /tmp/conjur-public-key.pem ${CACERTS} -storepass changeit -noprompt
