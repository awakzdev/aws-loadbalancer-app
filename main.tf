# ---------------------------------------------------------------------------
# An example terraform snippet to provision the following : 
/*
1. Two ubuntu VMs that will run an application
2. An ALB that will route the domain to the ALB on port 443, with an SSL certificate served by the ALB and a single target group containing both VMs listening on port 80.
3. An RDS database running mysql for the application to access. All components should run in a VPC, in separate subnets, and for the VMs and the load balancer internals, the subnets should be in separate AZs. The configuration should be secured so that the only connectivity allowed is the following:
4. SSH from the internet to the VMs
5. Port 80 and 443 between the load balancer internal IPs to the VMs
6. Port 80 and 443 from the internet to the load balancer (with port 80 automatically redirecting to 443)
7. Port 3306 from the VMs to the RDS
*/
# ---------------------------------------------------------------------------


####################
#
#     Network
#
####################
resource "aws_vpc" "main" {
  cidr_block         = local.json.vpc.cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each                = local.api
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = each.value.subnet_az

  tags = {
    Terraform = "True"
    Name      = "${var.name_prefix}-${each.key}"
  }
}

resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }

  tags = {
    Name = "${var.name_prefix}-rt"
  }
}

resource "aws_route_table_association" "rta" {
  for_each       = local.api
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_db_subnet_group" "db_subnet_grp" {
  name = lower("${var.name_prefix}-db-subnet-group")
  subnet_ids = [
    aws_subnet.public["vpc-subnet-one"].id,
    aws_subnet.public["vpc-subnet-two"].id
  ]

  tags = {
    Name = "${var.name_prefix}-rta"
  }
}

####################
#
#  Virtual-Machine
#
####################
data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] # Pulls the most recent AMI - set by *
  }
}

resource "aws_instance" "ec2" {
  for_each               = local.api
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.public[each.key].id
  availability_zone      = each.value.subnet_az
  user_data              = file("userdata/install_nginx.sh")

  tags = {
    Terraform = "True"
    Name      = "${var.name_prefix}-${each.key}"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.ssh_key}"
  public_key = file("~/.ssh/${var.ssh_key}.pub")
}

####################
#
#     Database
#
####################
resource "aws_db_instance" "db" {
  allocated_storage      = 20
  storage_type           = var.db_storage_type
  identifier              = "${var.name_prefix}-rds"
  engine                 = var.db_engine
  engine_version         = var.db_version == "" ? null : var.db_version
  instance_class         = var.db_instance_class == "" ? "db.t2.micro" : var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  availability_zone      = "eu-central-1a"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_grp.id
  skip_final_snapshot    = true

  tags = {
    Name = "${var.name_prefix}-db"
  }
}


####################
#
#     Security
#
####################
resource "aws_security_group_rule" "db_ec2_traffic" {
  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "http_alb_to_ec2" {
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-RDS-SG"
  description = "Allow Outbound RDS traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.name_prefix}-ALB-SG"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.name_prefix}-EC2-SG"
  description = "Allows SSH to EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-ec2-sg"
  }
}


####################
#
#  Certificate - ACM
#
####################
resource "aws_acm_certificate" "ssl" {
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-alb-ssl"
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.ssl.arn
  validation_record_fqdns = [for record in aws_route53_record.main_route53 : record.fqdn]
}
  
####################
#
#   Route 53 - DNS
#
####################
data "aws_route53_zone" "retrive_route53" {
  name         = var.route53_zone
  private_zone = false
}

resource "aws_route53_record" "a_record_route53" {
  zone_id = data.aws_route53_zone.retrive_route53.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "main_route53" {
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
  zone_id         = data.aws_route53_zone.retrive_route53.zone_id
}

####################
#
#   Load Balancer
#
####################
resource "aws_lb" "alb" {
  name               = "${var.name_prefix}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public["vpc-subnet-one"].id,
    aws_subnet.public["vpc-subnet-two"].id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_listener" "alb_listener_tls" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ssl.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}

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

resource "aws_lb_target_group" "alb_target" {
  name     = "${var.name_prefix}-terraform-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "group" {
  for_each         = local.api
  target_group_arn = aws_lb_target_group.alb_target.arn
  target_id        = aws_instance.ec2[each.key].id
  port             = 80
}
