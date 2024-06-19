#!/bin/bash
host=assaf-lab.secretsmgr.cyberark.cloud
port=443

openssl s_client -showcerts -connect $host:$port < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > conjur.crt