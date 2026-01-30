################################################################################
# Dev Environment Configuration
################################################################################

# 프로젝트 기본 정보
project_name        = "tf-lab"
env_name            = "dev"
aws_region          = "ap-northeast-2"
localstack_endpoint = "http://localhost:4566"

################################################################################
# VPC Configuration
################################################################################
vpc_cidr = "10.0.0.0/16"
azs      = ["ap-northeast-2a"]  # Single AZ for cost saving

public_subnet_cidrs = [
  "10.0.1.0/24",
]

private_app_subnet_cidrs = [
  "10.0.11.0/24",
]

private_db_subnet_cidrs = [
  "10.0.21.0/24",
]

################################################################################
# Security Groups
################################################################################
admin_ssh_cidrs = ["0.0.0.0/0"]

################################################################################
# Compute Configuration
################################################################################
ami_id        = "ami-0c9c942bd7bf113a2"  # Amazon Linux 2023
instance_type = "t2.micro"

# Auto Scaling Group
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

################################################################################
# RDS Configuration
################################################################################
db_engine         = "mysql"
db_engine_version = "8.0.35"
db_instance_class = "db.t3.micro"
db_name           = "devdb"
db_username       = "devadmin"
db_password       = "DevPassword123!"  # TODO: Use Secrets Manager in production
db_multi_az       = false  # Single AZ for dev

################################################################################
# Tags
################################################################################
# 공통 태그는 main.tf의 locals에서 자동 생성됨
