# env/local/terraform.tfvars
# local(LocalStack) 환경에서 사용할 변수 값 모음
# - terraform plan/apply 시 -var-file로 주입한다.
# 예) terraform plan -var-file=env/local/terraform.tfvars

aws_region          = "ap-northeast-2"
localstack_endpoint = "http://localhost:4566"

env_name     = "local"
project_name = "tf-lab"

vpc_cidr = "10.10.0.0/16"

# public subnet은 AZ 개수와 CIDR 개수가 1:1로 매칭되어야 한다.
azs = ["ap-northeast-2a", "ap-northeast-2c"]

public_subnet_cidrs = [
  "10.10.1.0/24",
  "10.10.2.0/24",
]