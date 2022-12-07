####################
#      Network
####################

# Main VPC
resource "aws_vpc" "main" {
  cidr_block         = local.json.vpc.cidr
  enable_dns_support = true

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
    Name = "${each.key}"
  }
}

# Internet Gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-gw"
  }
}

# Routing table - Linking GW
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

# Database Subnet group - Minimum 2 AZ required
resource "aws_db_subnet_group" "default" {
  name = "main"
  subnet_ids = [
    aws_subnet.public["vpc-subnet-one"].id,
    aws_subnet.public["vpc-subnet-two"].id
  ]

  tags = {
    Name = "db-subnet"
  }
}


####################
#  Virtual-Machine
####################

# EC2 Instance on 2 different AZ's
resource "aws_instance" "ec2" {
  for_each               = local.api
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.public.id
  availability_zone      = each.value.subnet_az
  user_data              = file("userdata/install_apache.sh")

  tags = {
    Name = "ubuntu-${each.key}"
  }
}

# VM Key pair
resource "aws_key_pair" "auth" {
  key_name   = "key"
  public_key = file("~/.ssh/key.pub")
}


####################
#     Database
####################

# RDS MySQL - Single AZ (eu-central-1a)
resource "aws_db_instance" "db" {
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


####################
#     Security
####################

# SG Role - Allows EC2 to ALB Connection 
resource "aws_security_group_rule" "db_ec2_traffic" {
  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
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

# SG - RDS Reserved for SG Role
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "allows outbound rds traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "rds-sg"
  }
}

# SG - ALB Inbound Internet traffic
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "allows inbound alb traffic"
  vpc_id      = aws_vpc.main.id

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
    Name = "alb-ingress-sg"
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
    Name = "ec2-egress-sg"
  }
}


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

# Route 53 - Certificate Record
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
  zone_id         = data.aws_route53_zone.example.zone_id
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


####################
#   Load Balancer
####################

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

# ALB HTTPS Listener - TLS Certificate
resource "aws_lb_listener" "alb_listener_tls" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ssl.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target.arn
  }
}

# ALB HTTPS Listener - Redirects HTTP ALB DNS traffic to domain URL
resource "aws_lb_listener" "alb_listener_redirect" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    order = 1
    type  = "redirect"
    redirect {
      host        = aws_acm_certificate.ssl.domain_name
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

# ALB Target Group - Receives HTTP traffic
resource "aws_lb_target_group" "alb-target" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# ALB - Target Group on port 80 / Register VMs
resource "aws_lb_target_group_attachment" "group" {
  for_each         = local.api
  target_group_arn = aws_lb_target_group.alb-target.arn
  target_id        = aws_instance.ec2[each.key].id
  port             = 80
}
