# outputs.tf
# Terraform apply 이후 생성된 리소스의 주요 식별자/연결 정보를 output으로 노출한다.
# - terraform output / terraform output -raw <name> 으로 조회 가능
# - output은 모듈 간 연결(상위/하위 모듈)과 운영 확인에 사용한다.

# 사용 예:
#   terraform output
#   terraform output vpc_id
#   terraform output -raw vpc_id

# VPC ID
output "vpc_id" {
  value = aws_vpc.main.id
}

# Public Subnet ID(s)
# - 단일 subnet이면 public_subnet_id 사용
# - 다중(AZ 분산) subnet이면 public_subnet_ids 사용
#   (aws_subnet.public가 count/for_each로 여러 개 생성되는 구조여야 함)

# output "public_subnet_id" {
#   value = aws_subnet.public.id
# }

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

# Security Group ID
output "security_group_id" {
  value = aws_security_group.web.id
}

# 민감정보 출력은 최소화 권장
# - sensitive=true여도 state에 저장되며, 권한이 있으면 output으로 추출 가능
# - 정말 필요할 때만 사용
# output "db_password" {
#   value     = var.db_password
#   sensitive = true
# }