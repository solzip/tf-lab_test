# Terraform state(상태)를 저장/조회할 backend를 선언한다.
# 이 프로젝트는 remote state로 S3 backend를 사용한다.
#
# - backend 설정은 terraform plan/apply가 아니라 terraform init 시점에 초기화된다.
# - bucket/key/region/dynamodb_table 등의 구체 값은 코드에 하드코딩하지 않고
#   env/<env>/backend.hcl 파일을 -backend-config로 주입한다.
#
# 예)
#   terraform init -reconfigure -backend-config=env/local/backend.hcl

terraform {
  backend "s3" {}
}