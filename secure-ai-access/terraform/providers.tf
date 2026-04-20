terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      I_Owner             = "ajh-cli"
      Owner               = "ajh"
      I_Purpose           = "DevSecOps_SME_Lab"
      Project             = "secure-ai-access-demo"
      CA_iTMExclude       = "YES"
      CA_iTMExcludeReason = "DevSecOps SME machine"
    }
  }
}
