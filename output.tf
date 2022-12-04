output "domain" { value = "https://${aws_acm_certificate.ssl.domain_name}" }
output "endpoint" { value = aws_db_instance.db.endpoint }
output "alb" { value = aws_lb.alb.dns_name }
output "ec2" { value = { "EC2-ubuntu-one" : aws_instance.ec2["vpc-subnet-one"].public_ip, "EC2-ubuntu-two" : aws_instance.ec2["vpc-subnet-two"].public_ip } }

