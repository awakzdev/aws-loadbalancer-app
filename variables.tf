variable "route53_zone" {
  type        = string
  description = "Route53 zone name pointing to your domain - domain.com"
}

variable "sub_domain" {
  type        = string
  description = "Your subdomain - foo.domain.com"
}

