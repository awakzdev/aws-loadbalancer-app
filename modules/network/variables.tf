variable "aws_region" {
  type        = string
  description = "Region where all AWS Resources will be created"
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

variable "name_prefix" {
  type        = string
  description = "Common naming for tagged resources"
}
