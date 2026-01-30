# KMS Module

데이터 암호화를 위한 AWS KMS (Key Management Service) 키를 관리하는 모듈입니다.

## 기능

- RDS 암호화용 KMS Key 생성
- S3 Backend 암호화용 KMS Key 생성
- EBS 볼륨 암호화용 KMS Key 생성 (선택적)
- 자동 키 로테이션 지원
- 환경별 삭제 기간 설정 가능

## 사용 예제

```hcl
module "kms" {
  source = "../../modules/kms"

  project_name            = "tf-lab"
  env_name               = "dev"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  create_ebs_key         = false

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
| deletion_window_in_days | KMS key deletion window in days (7-30) | number | 30 | no |
| enable_key_rotation | Enable automatic key rotation | bool | true | no |
| create_ebs_key | Create KMS key for EBS encryption | bool | false | no |
| common_tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| rds_key_arn | ARN of RDS KMS key |
| rds_key_id | ID of RDS KMS key |
| s3_key_arn | ARN of S3 KMS key |
| s3_key_id | ID of S3 KMS key |
| ebs_key_arn | ARN of EBS KMS key |

## KMS Key 종류

### 1. RDS 암호화 Key
- 목적: RDS 데이터베이스 저장 시 암호화
- 자동 로테이션: 활성화 (권장)

### 2. S3 암호화 Key
- 목적: Terraform State 파일 암호화
- 자동 로테이션: 활성화 (권장)

### 3. EBS 암호화 Key (선택적)
- 목적: EC2 EBS 볼륨 암호화
- 사용 시: `create_ebs_key = true`

## 보안 고려사항

1. **키 로테이션**: 자동 키 로테이션 활성화 (매년)
2. **삭제 보호**: 7-30일 삭제 대기 기간 설정
3. **환경별 키 분리**: Dev, Staging, Prod 각각 독립적인 키 사용
4. **접근 제어**: IAM 정책으로 키 사용 권한 제한

## 비용

- KMS Key: $1/월 per key
- API 요청: 처음 20,000건 무료, 이후 $0.03/10,000건

예상 비용 (3개 환경):
- Dev: $2/월 (RDS + S3)
- Staging: $2/월 (RDS + S3)
- Prod: $2/월 (RDS + S3)

## 참고 자료

- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [Terraform aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)
