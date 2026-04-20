variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_id" {
  description = "Existing VPC ID where the demo will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the demo EC2 instances"
  type        = string
}

variable "sg_id" {
  description = "ID of your existing Security Group"
  type        = string
}

variable "key_name" {
  description = "Name of your EC2 Key Pair to allow SSH access"
  type        = string
  default     = ""
}

variable "demo_tag_prefix" {
  description = "Prefix for all demo resources (easy cleanup later)"
  type        = string
  default     = "ajh"
}
