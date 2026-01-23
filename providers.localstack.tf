# providers.localstack.tf
# AWS Provider 설정 파일

# 목적
# - 이 프로젝트는 LocalStack을 사용하여 AWS 리소스(S3/DynamoDB/EC2/VPC 등)를 로컬에서 모의 실행한다.
# - 따라서 실제 AWS로 요청하지 않도록 endpoint를 LocalStack으로 강제하고,
#   LocalStack 환경에서 불필요한 AWS 검증 단계(자격증명 검증, 메타데이터 조회 등)를 스킵한다.

# 주의사항(중요)
# - 아래 설정은 LocalStack 전용이다. 운영/실 AWS 환경에서는 사용하면 안 된다.
# - 특히 access_key/secret_key/token 하드코딩은 커밋/유출 리스크가 있으므로,
#   로컬이라도 환경변수 또는 tfvars로 분리하는 것이 안전하다.
# - skip_* 옵션은 실 AWS에서 계정/권한/리전 검증을 우회할 수 있어, 운영 환경에서는 제거해야 한다.

provider "aws" {
  # 리전은 AWS API 호출의 필수 파라미터이며, LocalStack에서도 형식상 필요하다.
  region = var.aws_region

  # LocalStack에서는 실제 AWS 자격증명이 필요하지 않다.
  # 다만 provider가 기본 자격증명을 요구하기 때문에 더미 값을 사용한다.
  # 권장: 코드 하드코딩 대신 환경변수(AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY) 또는 tfvars로 관리
  access_key = "test"
  secret_key = "test"
  token      = "test"

  # LocalStack endpoint로 각 AWS 서비스 요청을 라우팅한다.
  # - 여기서 지정한 서비스에 대해 AWS SDK 호출이 실제 AWS가 아닌 LocalStack으로 전달된다.
  endpoints {
    s3       = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    sts      = var.localstack_endpoint
    iam      = var.localstack_endpoint

    # VPC/서브넷/라우팅테이블/보안그룹 등 네트워킹 리소스는 AWS에서 EC2 API로 관리된다.
    # 따라서 VPC를 만들려면 ec2 endpoint가 반드시 LocalStack을 가리키도록 설정해야 한다.
    ec2 = var.localstack_endpoint
  }

  # LocalStack/MinIO 계열에서는 S3 virtual-hosted-style 대신 path-style이 필요한 경우가 많다.
  # 예: http://localhost:4566/bucket/key 형태
  s3_use_path_style = true

  # LocalStack에서는 아래 검증들이 실패하거나 의미가 없을 수 있어 스킵한다.
  # - credentials_validation: 실제 AWS credential 유효성 검사
  # - metadata_api_check: EC2 metadata API(169.254.169.254) 접근 검사
  # - requesting_account_id: STS로 account_id 조회(로컬에서는 불필요/실패 가능)
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # 모든 리소스에 공통으로 붙는 기본 태그
  # - 프로젝트/환경 구분 및 운영 관리(검색/정리)에 유용
  default_tags {
    tags = {
      Project = var.project_name
      Managed = "terraform"
      Env     = var.env_name
    }
  }
}