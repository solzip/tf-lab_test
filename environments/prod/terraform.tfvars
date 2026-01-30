################################################################################
# Production Environment Configuration
################################################################################

# 프로젝트 기본 정보
project_name        = "tf-lab"
env_name            = "prod"
aws_region          = "ap-northeast-2"
localstack_endpoint = "http://localhost:4566"

################################################################################
# VPC Configuration
################################################################################
vpc_cidr = "10.2.0.0/16"
azs      = ["ap-northeast-2a", "ap-northeast-2c"]  # Multi-AZ

public_subnet_cidrs = [
  "10.2.1.0/24",
  "10.2.2.0/24",
]

private_app_subnet_cidrs = [
  "10.2.11.0/24",
  "10.2.12.0/24",
]

private_db_subnet_cidrs = [
  "10.2.21.0/24",
  "10.2.22.0/24",
]

################################################################################
# Security Groups
################################################################################
# 관리자 IP 주소 (SSH 접근 허용)
# ⚠️ CRITICAL: Production 환경은 매우 제한적 접근만 허용
# VPN 또는 고정 IP를 가진 운영팀만 접근 가능
admin_ssh_cidrs = [
  "1.2.3.4/32",  # 운영팀 고정 IP만 (실제 IP로 변경 필수)
]

################################################################################
# Compute Configuration
################################################################################
ami_id        = "ami-0c9c942bd7bf113a2"  # Amazon Linux 2023
instance_type = "t3.medium"

# Auto Scaling Group
asg_min_size         = 2
asg_max_size         = 10
asg_desired_capacity = 4

################################################################################
# RDS Configuration
################################################################################
db_engine         = "mysql"
db_engine_version = "8.0.35"
db_instance_class = "db.t3.medium"
db_name           = "proddb"
db_username       = "prodadmin"
db_password       = "ProductionPassword123!"  # TODO: Use Secrets Manager (REQUIRED)
db_multi_az       = true  # Multi-AZ for production

################################################################################
# Tags
################################################################################
# 공통 태그는 main.tf의 locals에서 자동 생성됨
