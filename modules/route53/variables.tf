variable "domain_alias" {
  type        = string
  description = "Apex alias for record 'A' record - Must match 'domain' with prefix (prefix.domain.com)"
}

variable "environment" {
  type        = string
  description = "Environment naming convention - prod, dev, testing"
}

variable "domain_name" {
  type        = string
  description = "Registered domain name here"
}

variable "dns_name" {
  type        = string
  description = "Application load balancer zone Name"
}

variable "zone_id" {
  type        = string
  description = "Application load balancer zone ID"
}