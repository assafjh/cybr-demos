#!/bin/bash
# WARNING: this command will reveal the stored secret in plain text
#
#============ Variables ===============
# Using kubectl/oc
COP_CLI=kubectl

#============ Script ===============
# Assuming the secret name is "secret1", this will show the value
echo secret1: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret1}"  | base64 --decode && echo)"
echo secret2: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret2}"  | base64 --decode && echo)"
echo secret3: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret3}"  | base64 --decode && echo)"
echo secret4: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret4}"  | base64 --decode && echo)"
echo secret5: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret5}"  | base64 --decode && echo)"
echo secret6: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret6}"  | base64 --decode && echo)"
echo secret7: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret7}"  | base64 --decode && echo)"
echo secret8: "$($COP_CLI get secret -n conjur-external-secrets conjur -o jsonpath="{.data.secret8}"  | base64 --decode && echo)"