output "ec2_id" { value = aws_instance.ec2[*].id }
output "key_pair_id" { value = aws_key_pair.auth.id }
output "ec2_sg" { value = aws_security_group.ec2_sg.id }
output "vpc_id" { value = module.network.vpc_id }
output "subnet_id" { value = module.network.subnet_id }
output "subnet_cidr" { value = module.network.subnet_cidr }
output "db_subnet" { value = module.network.db_subnet }