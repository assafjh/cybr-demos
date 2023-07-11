terraform {
 required_providers {  
   conjur = {  
     source  = "cyberark/conjur"  
   }  
 }
}

provider "conjur" {
}

data "conjur_secret" "secretvar" {  
 name = "data/terraform/plans/safe/envvars/secret2"
}  

output "envvars_output" {  
 value = "${data.conjur_secret.secretvar.value}"

 # Must mark this output value as sensitive for Terraform v0.15+,  
 # because it's derived from a Conjur variable value that is declared  
 # as sensitive.  
 sensitive = true
}  
