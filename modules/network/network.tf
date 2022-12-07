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

# Internet Gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Gateway-${var.name_prefix}"
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
    Name = "route-${var.name_prefix}"
  }
}

# Route Table Association - Bridge for Subnet
resource "aws_route_table_association" "rt_a" {
  count = length(var.subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.rt.id
}

# Database Subnet group - Minimum 2 AZ required
resource "aws_db_subnet_group" "default" {
  name       = "subnet-${var.name_prefix}"
  subnet_ids = [for k in aws_subnet.public : k.id]

  tags = {
    Name = "rds-subnet-${var.name_prefix}"
  }
}