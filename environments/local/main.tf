# environments/local/main.tf
# Local 환경 - 모듈 조합

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name             = var.project_name
  env_name                 = var.env_name
  vpc_cidr                 = var.vpc_cidr
  azs                      = var.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name    = var.project_name
  env_name        = var.env_name
  vpc_id          = module.vpc.vpc_id
  admin_ssh_cidrs = var.admin_ssh_cidrs
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  env_name          = var.env_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project_name         = var.project_name
  env_name             = var.env_name
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  private_subnet_ids   = module.vpc.private_app_subnet_ids
  public_subnet_ids    = module.vpc.public_subnet_ids
  app_sg_id            = module.security_groups.app_sg_id
  bastion_sg_id        = module.security_groups.bastion_sg_id
  target_group_arn     = module.alb.target_group_arn
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  user_data            = file("${path.module}/user-data.sh")
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name              = var.project_name
  env_name                  = var.env_name
  private_db_subnet_ids     = module.vpc.private_db_subnet_ids
  db_sg_id                  = module.security_groups.db_sg_id
  db_engine                 = var.db_engine
  db_engine_version         = var.db_engine_version
  db_parameter_group_family = "mysql8.0"
  db_instance_class         = var.db_instance_class
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  db_multi_az               = var.db_multi_az
}
