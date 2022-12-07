output "database_name" { value = aws_db_instance.db.id }
output "host" { value = aws_db_instance.db.address }
output "security_group_id" { value = aws_security_group.rds_sg.id }
output "username" { value = aws_db_instance.db.username }