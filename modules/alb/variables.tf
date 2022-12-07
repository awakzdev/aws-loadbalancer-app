variable "name_prefix" {
  type        = string
  description = "Common naming for tagged resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC where the resources will be created"
}

variable "subnet_cidrs" {
  type        = list(any)
  description = "A list of Subnets CIDR's - Should consist of minimum 2"
}

variable "az" {
  type        = list(any)
  description = "Availability-Zones - Should match numbers of CIDRs given and AWS Region"
}

variable "key_pair_name" {
  type        = string
  description = "Key pair naming"
}

variable "ssh_file_name" {
  type        = string
  description = "Your SSH key.pub naming should match this"
}

variable "domain_name_alias" {
  type        = string
  description = "A domain you want to issue the certificate for"
}

variable "environment" {
  type        = string
  description = "Working environment - i.e (prod, staging, dev)"
}

variable "aws_region" {
  type        = string
  description = "Region where all AWS Resources will be created"
}