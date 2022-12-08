variable "ec2_sg" {
  type        = string
  description = "Security group for EC2 Instance - SG Role (Pairing)"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
}

variable "domain_alias" {
  type        = string
  description = "A domain you want to issue the certificate for"
}

variable "environment" {
  type        = string
  description = "Working environment - i.e (prod, staging, dev)"
}

variable "name_prefix" {
  type        = string
  description = "Common naming for tagged resources"
}

variable "subnet_id" {
  type        = any
  description = "AWS VPC Subnet ID(s)"
}

variable "subnet_cidrs" {
  type        = list(any)
  description = "A list of Subnets CIDR's - Should consist of minimum 2"
}

variable "ec2_id" {
  type        = any
  description = "AWS EC2 Instance ID(s)"
}