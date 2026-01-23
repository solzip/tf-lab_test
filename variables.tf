# variables.tf
# Terraform 구성에 사용되는 입력 변수 정의 파일

# 목적
# - 환경(local/dev/prod)별로 달라질 수 있는 값들을 코드(main.tf, providers.tf 등)에서 분리
# - 동일한 인프라 코드를 여러 환경에서 재사용 가능하게 함

# 사용 방식
# - 기본값(default)은 로컬(LocalStack) 개발 환경 기준
# - 다른 환경에서는 env/<env>/terraform.tfvars 또는 -var 옵션으로 오버라이드

# 프로젝트 이름
# - 리소스 Name 태그 및 공통 태그에 사용
# - 여러 프로젝트를 동시에 관리할 때 구분용
variable "project_name" {
  type    = string
  default = "tf-lab"
}

# 환경 이름
# - 리소스 태그 및 네이밍 규칙에 사용
# - 예: local / dev / prod
variable "env_name" {
  type    = string
  default = "local"
}

# AWS 리전
# - LocalStack에서도 형식상 필요
# - 실제 AWS 환경에서는 해당 리전에 리소스가 생성됨
variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

# LocalStack endpoint URL
# - AWS provider가 실제 AWS가 아닌 LocalStack으로 요청을 보내도록 지정
# - 스킴(http://) 포함 권장
variable "localstack_endpoint" {
  type    = string
  default = "http://localhost:4566"
}

# VPC CIDR 블록
# - 전체 네트워크 대역
# - public/private subnet CIDR은 이 범위 내에 있어야 함
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

# Public Subnet CIDR 목록
# - 다중 AZ 구성을 위한 퍼블릭 서브넷 CIDR 리스트
# - 각 CIDR은 azs 변수의 AZ와 1:1 매핑된다.
# - 예:
#   public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
# 주의:
# - azs 리스트와 길이가 반드시 같아야 한다.
# - 단일 퍼블릭 서브넷만 사용할 경우에도 리스트 형태로 유지하는 것이 확장에 유리하다.
variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (one per AZ)"
  type        = list(string)
}

# Availability Zones 목록
# - 퍼블릭 서브넷이 생성될 AZ 목록
# - public_subnet_cidrs와 index 기준으로 매칭됨
# - 예:
#   azs = ["ap-northeast-2a", "ap-northeast-2c"]
variable "azs" {
  description = "Availability Zones to use"
  type        = list(string)
}