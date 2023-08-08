route53_zone="cclab.cloud-castles.com" # Your Route53 domain.
domain="nginx-terraform.cclab.cloud-castles.com" # Your website will be available under this host name
name_prefix="staging" # Your environment or naming prefix (Staging, Dev, Production)
ssh_key="id_ed25519" # A .pub extension will be added to your name.
db_engine="mysql" # Database engine (mysql, postgres, mariadb, aurora...)
db_name="rds" # Your RDS name.
db_username="admin" # Must begin with a letter and contain only alphanumeric characters.
db_password="password" # Minimum of 8 characters
