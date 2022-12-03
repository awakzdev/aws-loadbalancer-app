# Main VPC
resource "aws_vpc" "main" {
  cidr_block = local.json.vpc.cidr

  tags = {
    Name = "dev-vpc"
  }
}

# Two Subnets in different AZ - Public IP on launch
resource "aws_subnet" "public" {
  for_each                = local.api
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = each.value.subnet_az

  tags = {
    Name = "dev-subnet"
  }
}

# Database Subnet group - Minimum 2 AZ required
resource "aws_db_subnet_group" "default" {
  name = "main"
  subnet_ids = [
    aws_subnet.public["vpc-subnet-one"].id,
    aws_subnet.public["vpc-subnet-two"].id
  ]

  tags = {
    Name = "My DB subnet group"
  }
}

# ENI with EC2 Security Groups attached
resource "aws_network_interface" "eni" {
  for_each        = local.api
  subnet_id       = aws_subnet.public[each.key].id
  private_ips     = [each.value.subnet_private_ip]
  security_groups = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "primary_network_interface"
  }
}

# Main Internet Gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-gw"
  }
}

# Main Routing table - GW Link
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route-table"
  }
}

# Route Table Association - Bridge for Subnet
resource "aws_route_table_association" "rt_a" {
  for_each       = local.api
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.rt.id
}

# EC2 Instance with ENI Attached on 2 AZ
resource "aws_instance" "ec2" {
  for_each      = local.api
  instance_type = "t2.micro"
  ami           = data.aws_ami.server_ami.id
  key_name      = aws_key_pair.auth.id
  user_data     = file("install_apache.sh")

  network_interface {
    network_interface_id = aws_network_interface.eni[each.key].id
    device_index         = 0
  }

  tags = {
    Name = "ubuntu-node"
  }
}

# RDS MySQL - Single AZ (eu-central-1a)
resource "aws_db_instance" "rds_instance" {
  allocated_storage      = 20
  identifier             = "rds-terraform"
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.27"
  instance_class         = "db.t2.micro"
  db_name                = "rds_mysql"
  username               = "admin"
  password               = "password"
  availability_zone      = "eu-central-1a"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.id
  skip_final_snapshot    = true

  tags = {
    Name = "RDSServerInstance"
  }
}

# SG Role - Allows EC2 to ALB Connection 
resource "aws_security_group_rule" "db_ec2_traffic" {
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ec2_sg.id
}

# SG Role - Allows EC2 to DB Connection 
resource "aws_security_group_rule" "ingress_ec2_traffic" {
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

# SG Role - Allows ALB to EC2 Connection 
resource "aws_security_group_rule" "egress_alb_traffic" {
  type                     = "egress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.ec2_sg.id
}

# EC2 SSH And Database connection
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "allows outbound rds traffic"
  vpc_id      = aws_vpc.main.id

  # Egress - Internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# SG - ALB Inbound Internet traffic
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "allows inbound alb traffic"
  vpc_id      = aws_vpc.main.id

  # Delete after successfully implementing certification 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# SG - EC2 SSH And Database connection
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "allow ssh to ec2"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress - Internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Database connection
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# ACM Certificate 
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

# Route 53 Zone
resource "aws_route53_zone" "example" {
  name = "modules.cclab.cloud-castles.com"
}

# Route 53 Record
resource "aws_route53_record" "example" {
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
  zone_id         = aws_route53_zone.example.zone_id
}

# Application Load balancer - set to two different AZ's
resource "aws_lb" "alb" {
  name               = "alb-dev"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public["vpc-subnet-one"].id,
    aws_subnet.public["vpc-subnet-two"].id
  ]

  enable_deletion_protection = false

  tags = {
    Environment = "dev"
  }
}

# ALB Listener - Testing
resource "aws_lb_listener" "alb-listener-tls" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target.arn
  }
}

# # ALB HTTPS Listener - TLS Certificate (Registered domain required)
# resource "aws_lb_listener" "alb-listener-tls" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy = "ELBSecurityPolicy-2016-08"
#   certificate_arn = aws_acm_certificate.ssl.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.alb-target.arn
#   }
# }

# # ALB Listener - Redirect HTTP to HTTPS (Certificate needed)
# resource "aws_lb_listener" "alb-listener-redirect" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "redirect"

#     redirect {
#       port = "443"
#       protocol = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# ALB Target Group - Receives HTTP traffic
resource "aws_lb_target_group" "alb-target" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# ALB - VM Target Group on port 80
resource "aws_lb_target_group_attachment" "group" {
  for_each         = local.api
  target_group_arn = aws_lb_target_group.alb-target.arn
  target_id        = aws_instance.ec2[each.key].id
  port             = 80
}

# VM Key pair
resource "aws_key_pair" "auth" {
  key_name   = "key"
  public_key = file("~/.ssh/key.pub")
}

# Domain name on certificate 
output "domain_name" {
  value = "https://${aws_acm_certificate.ssl.domain_name}"
}

# VM IP address
output "instance_ip_addr" {
  value = {
    "EC2-ubuntu-one" : aws_instance.ec2["vpc-subnet-one"].public_ip,
    "EC2-ubuntu-two" : aws_instance.ec2["vpc-subnet-two"].public_ip
  }
}

# ALB DNS name
output "alb_dns" {
  value = aws_lb.alb.dns_name
}
