# versions.tf
# Terraform CLI 및 provider 버전 요구사항을 정의한다.
# 목적:
# - 팀/CI/서버 환경에서 동일한 버전 조합으로 실행되도록 재현성을 확보한다.
# - 과도한 버전 점프(특히 provider minor/major 변경)로 인한 예기치 않은 변경을 방지한다.

terraform {
  # Terraform CLI 최소 버전
  # - 이 프로젝트는 Terraform 1.5.0 이상에서만 실행 가능
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      # AWS provider는 HashiCorp 공식 provider를 사용
      source = "hashicorp/aws"

      # "~> 5.100" 의미:
      # - 5.100.x 패치 버전만 허용
      # - 5.101 이상(마이너 버전 업)은 허용하지 않음
      # - 실제 선택된 정확한 버전은 .terraform.lock.hcl로 고정됨
      version = "~> 5.100"
    }
  }
}