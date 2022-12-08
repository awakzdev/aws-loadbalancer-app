output "ec2_id" { value = aws_instance.ec2[*].id }
output "key_pair_id" { value = aws_key_pair.auth.id }
output "ec2_sg" { value = aws_security_group.ec2_sg.id }