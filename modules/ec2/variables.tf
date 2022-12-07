variable "ec2_name" {
  type        = string
  description = "Naming convention for EC2 VM"
}

variable "name_prefix" {
  type        = string
  description = "Naming convention for tagged resources"
}

variable "key_pair_name" {
  type        = string
  description = "Naming convention for key_pair"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR's to create resources on"
}

variable "subnet_cidrs" {
  type        = list(any)
  description = "Subnet CIDR's to create resources on - Minimum of 2"
}

variable "aws_region" {
  type        = string
  description = "AWS Region to create resources on"
}

variable "az" {
  type        = list(any)
  description = "Availability-Zones - Should match numbers of CIDRs given and AWS Region"
}

variable "ssh_file_name" {
  type        = string
  description = "Naming convention for your .pub SSH Key (key.pub)"
}