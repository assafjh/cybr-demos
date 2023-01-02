#!/bin/bash
#========== Variables ===============
ANSIBLE_VERSION=$(ansible --version | head -n 1)
ANSIBLE_VERSION=${ANSIBLE_VERSION#*[* }
ANSIBLE_VERSION=${ANSIBLE_VERSION%]*}
#========== Functions  ===============
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
TEST_VERSION() {
	COMPARE_VERSION "$1" "$2"
	case $? in
        	0) echo equal;;
	        1) echo newer;;
        	2) echo older;;
	esac
}
#========== Script ===============
echo "# auto-generated file" > conjur_env.properties
VERSION=$(TEST_VERSION "$ANSIBLE_VERSION" "2.8")
if [ "$VERSION" == "newer" ]; then
	VERSION=$(TEST_VERSION "$ANSIBLE_VERSION" "2.9")
	if [ $VERSION == "equal" ]; then
		echo "ANSIBLE_PLUGIN=new" >> conjur_env.properties
		echo "export LOOKUP_CMD=cyberark.conjur.conjur_variable" >> conjur_env.properties
	elif [ $VERSION == "older" ]; then
		echo "ANSIBLE_PLUGIN=old" >> conjur_env.properties
		echo "export LOOKUP_CMD=conjur_variable" >> conjur_env.properties
	else
		echo "ANSIBLE_PLUGIN=new" >> conjur_env.properties
		echo "export LOOKUP_CMD=cyberark.conjur.conjur_variable" >> conjur_env.properties
	fi
elif [ $VERSION == "equal" ]; then 
	echo "ANSIBLE_PLUGIN=old" >> conjur_env.properties
	echo "export LOOKUP_CMD=conjur_variable" >> conjur_env.properties
else
	echo "ANSIBLE_PLUGIN=not_supported" >> conjur_env.properties
fi
echo export ACCOUNT=$(curl -s -k https://127.0.0.1/info | awk '/account/ {print $2}' | tr -d '",') >> conjur_env.properties
echo export CONJUR_FQDN=$(curl -s -k https://127.0.0.1/info | awk '/hostname/ {print $2}' | tr -d '",') >> conjur_env.properties
