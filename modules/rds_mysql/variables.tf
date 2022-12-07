variable "name_prefix" {
  type        = string
  description = "Naming convention for tagged resources"
}

variable "database_name" {
  type        = string
  description = "Naming convention for Database"
}

variable "instance_class" {
  type        = string
  description = "Instance type - i.e db.tf2.micro"
}

variable "mysql_version" {
  type        = string
  description = "Database engine version - i.e 8.0.27"
}

variable "size_initial_gb" {
  type        = number
  description = "Enabling Database scaling - Issue a starting GB size - i.e 20"
}

variable "size_max_gb" {
  type        = number
  description = "Database max scale size (GB)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC where the resources will be created - Include a prefix i.e '/16'"
}

variable "subnet_cidrs" {
  type        = list(string)
  description = "A list of Subnets CIDR's - Should consist of minimum 2"
}

variable "aws_region" {
  type        = string
  description = "Region where all AWS Resources will be created"
}

variable "az" {
  type        = list(string)
  description = "Availability-Zones - Should match numbers of CIDRs given and AWS Region"
}

variable "ssh_file_name" {
  type        = string
  description = "Naming convention for your SSH file"
}

variable "key_pair_name" {
  type        = string
  description = "Your SSH key.pub naming convention - You'll have to create and rename SSH key accordingly"
}