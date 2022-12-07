output "domain_alias" { value = "https://${aws_acm_certificate.ssl.domain_name}" }
output "dns_name" { value = aws_lb.alb.dns_name }
output "zone_id" { value = aws_lb.alb.zone_id }