module "ec2" {
  source = "../ec2"

  ec2_name      = var.ec2_name
  name_prefix   = var.name_prefix
  key_pair_name = var.key_pair_name
  vpc_cidr      = var.vpc_cidr
  subnet_cidrs  = var.subnet_cidrs
  aws_region    = var.aws_region
  ssh_file_name = var.ssh_file_name
  az            = var.az
}

####################
#     Security
####################

# Database SG - Reserved for SG Role
resource "aws_security_group" "rds_sg" {
  name        = "mysql-sg-${var.name_prefix}"
  description = "Database - Reserved for SG Role"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-mysql"
  }
}

# SG Role - Allows RDS to EC2 Connection 
resource "aws_security_group_rule" "db_ec2_traffic" {
  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = module.ec2.ec2_sg
}

# SG Role - Allows EC2 to RDS Connection
resource "aws_security_group_rule" "ec2_db_traffic" {
  type                     = "egress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  security_group_id        = module.ec2.ec2_sg
  source_security_group_id = aws_security_group.rds_sg.id
}

####################
#      Network
####################

# Provider block
provider "aws" {
  region = var.aws_region
}

# Main VPC
resource "aws_vpc" "main" {
  cidr_block         = var.vpc_cidr
  enable_dns_support = true

  tags = {
    Name = "vpc-${var.name_prefix}"
  }
}

# Two Subnets in different AZ - Public IP on launch
resource "aws_subnet" "public" {
  count = length(var.subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.az[count.index]

  tags = {
    Name = "subnet-${var.name_prefix}-${count.index}"
  }
}

# Database Subnet
resource "aws_db_subnet_group" "db" {
  name = "${var.name_prefix}-mysql"
  subnet_ids = [
    aws_subnet.public[0].id,
  aws_subnet.public[1].id]
}


####################
#     Database
####################

# Generate a random password
resource "random_password" "admin" {
  length  = 32
  special = false
}

# RDS MySQL
resource "aws_db_instance" "db" {
  identifier = "${var.name_prefix}-mysql"

  allocated_storage     = var.size_initial_gb
  max_allocated_storage = var.size_max_gb

  engine              = "mysql"
  engine_version      = var.mysql_version
  instance_class      = var.instance_class
  skip_final_snapshot = true

  db_name  = var.database_name
  username = "root"
  password = random_password.admin.result

  availability_zone      = var.az[0]
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db.id

  tags = {
    Name = "RDS-${var.name_prefix}"
  }
}
