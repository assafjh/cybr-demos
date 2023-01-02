#!/bin/bash
#========== Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/conjur_env.properties
#========== Script ===============
if [ "$ANSIBLE_PLUGIN" == "new" ]; then
	ansible-galaxy collection install cyberark.conjur
elif [ "$ANSIBLE_PLUGIN" == "old" ]; then
	ansible-galaxy install cyberark.conjur-host-identity
else
	echo "Plugin not supported - Minimum version is Ansible 2.8"
fi
