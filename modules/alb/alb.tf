module "ec2" {
  source = "../ec2"

  name_prefix   = var.name_prefix
  subnet_cidrs  = var.subnet_cidrs
  key_pair_name = var.key_pair_name
  ssh_file_name = var.ssh_file_name
  az            = var.az
  aws_region    = var.aws_region
  vpc_cidr      = var.vpc_cidr
  ec2_name      = var.ec2_name
}

# SG Role - Allows ALB to EC2 Connection 
resource "aws_security_group_rule" "alb_ec2_traffic" {
  type                     = "egress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.ec2_sg.id
}

# SG - ALB Inbound Internet traffic
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "allows inbound alb traffic"
  vpc_id      = module.ec2.vpc_id

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

# SG Role - Allows EC2 to ALB Connection 
resource "aws_security_group_rule" "ec2_alb_traffic" {
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

# SG - EC2 SSH And Egress connection
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "allow ssh to ec2"
  vpc_id      = module.ec2.vpc_id

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

  tags = {
    Name = "ec2-egress-sg"
  }
}

####################
# ACM - Certificate
####################

# ACM Certificate issue
resource "aws_acm_certificate" "ssl" {
  domain_name       = var.domain_name_alias
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = var.environment
  }
}


####################
#   Load Balancer
####################

# Application Load balancer - set to two different AZ's
resource "aws_lb" "alb" {
  name               = var.name_prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [module.ec2.subnet_cidr[0], module.ec2.subnet_cidr[1]]

  enable_deletion_protection = false

  tags = {
    Environment = "${var.environment}"
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
    target_group_arn = aws_lb_target_group.alb_target.arn
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
resource "aws_lb_target_group" "alb_target" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.ec2.vpc_id
}

# ALB - Attach VM's on port 80
resource "aws_lb_target_group_attachment" "group" {
  count = length(var.subnet_cidrs)

  target_group_arn = aws_lb_target_group.alb_target.arn
  target_id        = module.ec2.ec2_id[count.index]
  port             = 80
}