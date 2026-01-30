# environments/dev/main.tf
# Dev 환경 - 보안 강화된 인프라

################################################################################
# Local Variables
################################################################################

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env_name
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

################################################################################
# Security Modules
################################################################################

# Random Password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager Module
module "secrets" {
  source = "../../modules/secrets"

  project_name        = var.project_name
  env_name           = var.env_name
  db_master_username = var.db_username
  db_master_password = random_password.db_password.result
  enable_rotation    = false  # Dev 환경은 로테이션 비활성화

  common_tags = local.common_tags
}

# KMS Module
module "kms" {
  source = "../../modules/kms"

  project_name            = var.project_name
  env_name               = var.env_name
  deletion_window_in_days = 7  # Dev: 빠른 삭제
  enable_key_rotation     = true
  create_ebs_key         = false

  common_tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_name           = var.project_name
  env_name              = var.env_name
  secrets_arns          = [module.secrets.secret_arn]
  enable_s3_access      = true
  enable_session_manager = false
  create_bastion_role   = true

  common_tags = local.common_tags
}

################################################################################
# Network & Infrastructure
################################################################################

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

  # VPC Flow Logs
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days
  flow_logs_traffic_type   = var.flow_logs_traffic_type
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

  # IAM Instance Profile (보안 강화)
  instance_profile_name         = module.iam.ec2_app_instance_profile_name
  bastion_instance_profile_name = module.iam.ec2_bastion_instance_profile_name
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
  db_password               = random_password.db_password.result
  db_multi_az               = var.db_multi_az

  # 보안 강화
  secret_arn        = module.secrets.secret_arn
  enable_encryption = true
  kms_key_arn       = module.kms.rds_key_arn

  depends_on = [module.secrets, module.kms]
}
