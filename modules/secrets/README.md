# Secrets Module

AWS Secrets Manager를 사용하여 RDS 데이터베이스 비밀번호를 안전하게 관리하는 모듈입니다.

## 기능

- RDS 마스터 비밀번호를 Secrets Manager에 저장
- 환경별 복구 기간 설정 (Dev: 7일, Prod: 30일)
- 자동 비밀번호 로테이션 지원 (Prod 환경)
- JSON 형식으로 비밀번호와 연결 정보 저장

## 사용 예제

```hcl
module "secrets" {
  source = "../../modules/secrets"

  project_name        = "tf-lab"
  env_name           = "dev"
  db_master_username = "admin"
  db_master_password = random_password.db_password.result
  db_endpoint        = module.rds.endpoint
  enable_rotation    = false

  common_tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | - | yes |
| env_name | Environment name | string | - | yes |
| db_master_username | RDS master username | string | "admin" | no |
| db_master_password | RDS master password | string | - | yes |
| db_endpoint | RDS endpoint | string | "" | no |
| enable_rotation | Enable automatic password rotation | bool | false | no |
| rotation_lambda_arn | Lambda ARN for password rotation | string | "" | no |
| common_tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arn | ARN of the secret |
| secret_id | ID of the secret |
| secret_name | Name of the secret |

## 보안 고려사항

1. **비밀번호 생성**: `random_password` 리소스를 사용하여 안전한 비밀번호 생성
2. **Lifecycle 정책**: `ignore_changes`로 수동 비밀번호 변경 보호
3. **복구 기간**: 실수로 삭제 시 복구 가능 (Dev: 7일, Prod: 30일)
4. **자동 로테이션**: Prod 환경에서 30일마다 자동 비밀번호 변경

## 참고 자료

- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform aws_secretsmanager_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
