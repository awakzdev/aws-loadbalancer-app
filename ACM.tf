####################
#  Certificate - ACM
####################

# ACM Certificate issue
resource "aws_acm_certificate" "ssl" {
  domain_name       = "modules.cclab.cloud-castles.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "test"
  }
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.ssl.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}

####################
#   Route 53 - DNS
####################

# Route 53 Zone
data "aws_route53_zone" "example" {
  name         = "cclab.cloud-castles.com"
  private_zone = false
}

# Route 53 - ALB Alias
resource "aws_route53_record" "alias_route53_record" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = "modules.cclab.cloud-castles.com"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
