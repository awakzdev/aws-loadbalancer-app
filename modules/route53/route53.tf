####################
#  ACM - Certificate
####################

# ACM Certificate issue
resource "aws_acm_certificate" "ssl" {
  domain_name       = var.domain_alias
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "${var.environment}-SSL-CERT"
  }
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "verify" {
  certificate_arn         = aws_acm_certificate.ssl.arn
  validation_record_fqdns = [for record in aws_route53_record.dns : record.fqdn]
}


####################
#   Route 53 - DNS
####################

# Route 53 Zone
data "aws_route53_zone" "dns" {
  name         = var.domain_name
  private_zone = false
}

# Route 53 - Certificate Record
resource "aws_route53_record" "dns" {
  for_each = {
    for dvo in aws_acm_certificate.ssl.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.dns.zone_id
}

# Route 53 - ALB Alias
resource "aws_route53_record" "alias_route53_record" {
  zone_id = data.aws_route53_zone.dns.zone_id
  name    = var.domain_alias
  type    = "A"

  alias {
    name                   = var.dns_name
    zone_id                = var.zone_id
    evaluate_target_health = true
  }
}