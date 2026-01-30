################################################################################
# Staging Environment Configuration
################################################################################

# 프로젝트 기본 정보
project_name        = "tf-lab"
env_name            = "staging"
aws_region          = "ap-northeast-2"
localstack_endpoint = "http://localhost:4566"

################################################################################
# VPC Configuration
################################################################################
vpc_cidr = "10.1.0.0/16"
azs      = ["ap-northeast-2a", "ap-northeast-2c"]  # Multi-AZ

public_subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24",
]

private_app_subnet_cidrs = [
  "10.1.11.0/24",
  "10.1.12.0/24",
]

private_db_subnet_cidrs = [
  "10.1.21.0/24",
  "10.1.22.0/24",
]

################################################################################
# Security Groups
################################################################################
# 관리자 IP 주소 (SSH 접근 허용)
# ⚠️ Staging은 Prod와 동일한 제한적 접근 정책 적용
admin_ssh_cidrs = [
  "1.2.3.4/32",  # 운영팀 IP만 (실제 IP로 변경)
]

################################################################################
# Compute Configuration
################################################################################
ami_id        = "ami-0c9c942bd7bf113a2"  # Amazon Linux 2023
instance_type = "t2.small"

# Auto Scaling Group
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2

################################################################################
# RDS Configuration
################################################################################
db_engine         = "mysql"
db_engine_version = "8.0.35"
db_instance_class = "db.t3.small"
db_name           = "stagingdb"
db_username       = "stagingadmin"
db_password       = "StagingPassword123!"  # TODO: Use Secrets Manager
db_multi_az       = true  # Multi-AZ for staging

################################################################################
# VPC Flow Logs
################################################################################
enable_flow_logs         = true
flow_logs_retention_days = 14   # Staging: 14일 보존
flow_logs_traffic_type   = "ALL"

################################################################################
# Tags
################################################################################
# 공통 태그는 main.tf의 locals에서 자동 생성됨
