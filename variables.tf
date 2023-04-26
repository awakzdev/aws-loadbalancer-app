variable "route53_zone" {
  type        = string
  description = "Route53 zone name pointing to your domain - domain.com"
}

variable "sub_domain" {
  type        = string
  description = "Your subdomain - foo.domain.com"
}

variable "name_prefix" {
  type        = string
  description = "Naming convention for AWS Resources"
}

variable "tags" {
  type = map(string)
  default = {
    "Terraform" = "True"
  }
}