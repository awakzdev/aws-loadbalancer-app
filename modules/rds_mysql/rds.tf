####################
#     Security
####################

# Database SG - Reserved for SG Role
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-${var.name_prefix}"
  description = "Database - Reserved for SG Role"
  vpc_id      = var.vpc_id

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
  source_security_group_id = var.ec2_sg
}

# SG Role - Allows EC2 to RDS Connection
resource "aws_security_group_rule" "ec2_db_traffic" {
  type                     = "egress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  security_group_id        = var.ec2_sg
  source_security_group_id = aws_security_group.rds_sg.id
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
  db_subnet_group_name   = var.db_subnet

  tags = {
    Name = "RDS-${var.name_prefix}"
  }
}
