# environments/local/terraform.tfvars
# Local 환경 변수 값

# 프로젝트 설정
project_name        = "tf-lab"
env_name            = "local"
aws_region          = "ap-northeast-2"
localstack_endpoint = "http://localhost:4566"

# VPC
vpc_cidr = "10.10.0.0/16"
azs      = ["ap-northeast-2a", "ap-northeast-2c"]

public_subnet_cidrs = [
  "10.10.1.0/24",
  "10.10.2.0/24",
]

private_app_subnet_cidrs = [
  "10.10.11.0/24",
  "10.10.12.0/24",
]

private_db_subnet_cidrs = [
  "10.10.21.0/24",
  "10.10.22.0/24",
]

# Security Groups
admin_ssh_cidrs = ["0.0.0.0/0"]

# Compute
ami_id        = "ami-12345678"
instance_type = "t3.micro"

asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2

# RDS
db_engine         = "mysql"
db_engine_version = "8.0.35"
db_instance_class = "db.t3.micro"
db_name           = "tflab"
db_username       = "admin"
db_password       = "changeme123!"
db_multi_az       = false
