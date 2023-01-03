#!/bin/bash
# This script installs Ansible galaxy plugin according to Ansible version

#========== Script ===============
# Loading functions snippet
source ./functions
# Plugin needed will be decided according to Ansible version
decide_values_for_playbook
if [ "$ANSIBLE_PLUGIN" == "new" ]; then
	ansible-galaxy collection install cyberark.conjur
elif [ "$ANSIBLE_PLUGIN" == "old" ]; then
	ansible-galaxy install cyberark.conjur-host-identity
else
	echo "Plugin not supported - Minimum version is Ansible 2.8"
fi
