module "network" {
  source = "../modules/network"

  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr
  subnet_cidrs = var.subnet_cidrs
  az           = var.az
  name_prefix  = var.name_prefix
}

data "aws_region" "current" {}

module "ec2" {
  source = "../modules/ec2"

  vpc_id        = module.network.vpc_id
  vpc_cidr      = module.network.vpc_cidr
  subnet_id     = module.network.subnet_id
  subnet_cidrs  = module.network.subnet_cidrs
  az            = module.network.subnet_az
  aws_region    = data.aws_region.current.id
  name_prefix   = var.name_prefix
  key_pair_name = var.key_pair_name
  ssh_file_name = var.ssh_file_name
}

module "alb" {
  source = "../modules/alb"

  ec2_sg       = module.ec2.ec2_sg
  vpc_id       = module.network.vpc_id
  subnet_id    = module.network.subnet_id
  subnet_cidrs = module.network.subnet_cidrs
  ec2_id       = module.ec2.ec2_id
  domain_alias = var.domain_alias
  environment  = var.environment
  name_prefix  = var.name_prefix
}

module "route53" {
  source = "../modules/route53"

  domain_alias = module.alb.domain_alias
  zone_id      = module.alb.zone_id
  dns_name     = module.alb.dns_name
  environment  = var.environment
  domain_name  = var.domain_name
}

module "rds_mysql" {
  source = "../modules/rds_mysql"

  vpc_id          = module.network.vpc_id
  ec2_sg          = module.ec2.ec2_sg
  az              = module.network.subnet_az
  name_prefix     = var.name_prefix
  size_initial_gb = var.size_initial_gb
  size_max_gb     = var.size_max_gb
  mysql_version   = var.mysql_version
  instance_class  = var.instance_class
  database_name   = var.database_name
  db_subnet       = module.network.db_subnet
}
