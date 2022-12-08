variable "name_prefix" {
  type        = string
  description = "Naming convention for tagged resources"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
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

variable "az" {
  type        = list(string)
  description = "Availability-Zones - Should match numbers of CIDRs given and AWS Region"
}

variable "db_subnet" {
  type        = string
  description = "Database Subnet ID"
}

