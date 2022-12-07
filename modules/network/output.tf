output "vpc_id" { value = aws_vpc.main.id }
output "subnet_id" { value = aws_subnet.public[*].id }
output "subnet_cidr" { value = aws_subnet.public[*].cidr_block }
output "db_subnet" { value = aws_db_subnet_group.default.id }