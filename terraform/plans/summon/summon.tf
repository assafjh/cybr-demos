variable "secret3" {}

terraform {  
 required_providers {  
    null  = {  
   }  
   }  
 }  

locals {
  secret_value = var.secret3
}

 output "summon_output" {  
 value = "${local.secret_value}"  

 # Must mark this output value as sensitive for Terraform v0.15+,
 # because it's derived from a Conjur variable value that is declared
 # as sensitive.
   sensitive = true
}
