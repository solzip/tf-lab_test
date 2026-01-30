################################################################################
# Production Environment Backend Configuration
################################################################################
# Terraform remote state backend(S3) 설정 값
# - terraform init 시점에 -backend-config로 주입된다.
# - LocalStack을 사용하므로 endpoint/skip 옵션을 LocalStack 친화적으로 설정한다.
# - 실제 AWS 배포 시 endpoint 관련 설정 제거 필요

region  = "ap-northeast-2"

# LocalStack에서는 SSE(encrypt)가 의미 없거나 제한적일 수 있어 false로 둔다.
# 실 AWS에서는 일반적으로 true를 사용한다. (REQUIRED for production)
encrypt = false

# state 저장 버킷/키 (Production 환경 전용)
bucket = "tfstate-prod"
key    = "tf-lab/prod/terraform.tfstate"

# state 락(lock)을 위한 DynamoDB 테이블 (Production 환경 전용)
# - 동시 apply로 인한 state 손상을 방지한다.
dynamodb_table = "terraform-locks-prod"

# LocalStack endpoints (학습 시만 사용, 실제 AWS 배포 시 아래 5줄 제거)
endpoint          = "http://localhost:4566"
dynamodb_endpoint = "http://localhost:4566"
sts_endpoint      = "http://localhost:4566"

# LocalStack에서는 실제 AWS 자격증명/계정 조회가 불필요하거나 실패할 수 있어 스킵한다.
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true

# LocalStack/MinIO 계열에서 S3 path-style URL이 필요한 경우가 많아 강제한다.
force_path_style = true