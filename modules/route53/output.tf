output "name_servers" { value = data.aws.route53_zone.dns.name_servers }
output "fqdn" { value = aws_route53_record.dns.fqdn }
output "alias" { value = aws_route53_record.alias_route53_record.name }
