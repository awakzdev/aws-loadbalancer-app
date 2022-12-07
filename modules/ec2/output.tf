output "subnet_id" { value = aws_subnet.public[*].id }
output "vpc_id" { value = aws_vpc.main.id }
output "ec2_id" { value = aws_instance.ec2[*].id }
output "key_pair_id" { value = aws_key_pair.auth.id }
output "ec2_sg" { value = aws_security_group.ec2_sg.id }
output "subnet_cidr" { value = aws_subnet.public[*].cidr_block }