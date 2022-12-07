output "vpc_id" { value = aws_vpc.main.id }
output "subnet_id" { value = aws_subnet.public[*].id }
output "subnet_cidr" { value = aws.subnet.public[*].subnet_cidr }