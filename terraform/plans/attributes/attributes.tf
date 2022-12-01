terraform {
 required_providers {  
   conjur = {  
     source  = "cyberark/conjur"  
   }  
 }
}

provider "conjur" {
    # Conjur FQDN including scheme and port
    appliance_url = "$CONJUR_APPLIANCE_URL"
    # Path to Conjur public key file
    ssl_cert_path = "$CONJUR_CERT_FILE"
    # Conjur Account
    account = "$CONJUR_ACCOUNT"
    # Conjur identity
    login = "$CONJUR_AUTHN_LOGIN"
    # Conjur identity api key
    api_key = "$CONJUR_AUTHN_API_KEY"
}

data "conjur_secret" "secretvar" {  
    name = "terraform/plans/safe/attributes/secret1"
}  

output "attributes_output" {  
    value = "${data.conjur_secret.secretvar.value}"  

    # Must mark this output value as sensitive for Terraform v0.15+,  
    # because it's derived from a Conjur variable value that is declared  
    # as sensitive.  
    sensitive = true  
}

