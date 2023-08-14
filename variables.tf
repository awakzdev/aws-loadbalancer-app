variable "aws_region" {
  type        = string
  description = "Your AWS Region in which resources will be deployed"
  default     = "eu-central-1"
}

variable "route53_zone" {
  type        = string
  description = "Route53 zone name pointing to your domain - domain.com"
}

variable "domain" {
  type        = string
  description = "Your websites domain - example.domain.com"
}

variable "name_prefix" {
  type        = string
  description = "Naming convention for AWS Resources"
}

variable "ssh_key" {
  type        = string
  description = "SSH Key (This will automatically add a .pub extension to your name)"
}

variable "tags" {
  type = map(string)
  description = "Your AWS resources will be tagged with the following"
  default = {
    "Terraform" = "True"
  }
}

variable "db_storage_type" {
  type = string
  default = "gp2"
  description = "Your database storage type"
}

variable "db_name" {
  type = string
  description = "Your database name"
}

variable "db_instance_class" {
  type = string
  default = ""
  description = "Your database size"
}

variable "db_engine" {
  type = string
  description = "Available types are - mysql, postgres, mariadb, aurora-mysql, aurora-postgresql"
}

variable "db_version" {
  type = string
  default = ""
  description = "Optional - Your database version. to see a list of available database versions please head over the 'RDS' section on AWS"
}

variable "db_username" {
  type = string
  description = "Your database username"
}

variable "db_password" {
  type = string
  description = "Your database password"
}
