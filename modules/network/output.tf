output "vpc_id" { value = aws_vpc.main.id }
output "subnet_id" { value = aws_subnet.public[*].id }
output "subnet_cidrs" { value = aws_subnet.public[*].cidr_block }
output "db_subnet" { value = aws_db_subnet_group.default.id }
output "vpc_cidr" { value = aws_vpc.main.cidr_block }
output "subnet_az" { value = aws_subnet.public[*].availability_zone }
