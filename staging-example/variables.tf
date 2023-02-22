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

variable "key_pair_name" {
  type        = string
  description = "Naming convention for key_pair"
}

variable "ssh_file_name" {
  type        = string
  description = "Naming convention for your .pub SSH Key (key.pub)"
}

variable "environment" {
  type        = string
  description = "Working environment - i.e (prod, staging, dev)"
}

variable "domain_alias" {
  type        = string
  description = "A domain you want to issue the certificate for"
}

variable "domain_name" {
  type        = string
  description = "Your registered domain name here"
}

variable "zone_id" {
  type        = string
  description = "Application load balancer ZONE ID"
}

variable "dns_name" {
  type        = string
  description = "Application load balancer ZONE ID"
}

variable "ec2_sg" {
  type        = string
  description = "Security group for EC2 Instance - SG Role (Pairing)"
}

variable "size_initial_gb" {
  type        = number
  description = "Enabling Database scaling - Issue a starting GB size - i.e 20"
}

variable "size_max_gb" {
  type        = number
  description = "Database max scale size (GB)"
}

variable "mysql_version" {
  type        = string
  description = "Database engine version - i.e 8.0.27"
}

variable "instance_class" {
  type        = string
  description = "Instance type - i.e db.tf2.micro"
}

variable "database_name" {
  type        = string
  description = "Naming convention for Database"
}

variable "route53_zone" {
  type        = string
  description = "Route53 zone name pointing to your domain - domain.com"
}

variable "sub_domain" {
  type        = string
  description = "Your subdomain - foo.domain.com"
}
