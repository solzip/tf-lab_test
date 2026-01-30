# IAM Module

EC2 인스턴스를 위한 IAM Role 및 Instance Profile을 생성하는 모듈입니다.

## 기능

- EC2 App 서버용 IAM Role 생성
- Secrets Manager 읽기 권한
- S3 읽기 권한 (애플리케이션 에셋)
- CloudWatch Logs 쓰기 권한
- Session Manager 지원 (선택적)
- Bastion 호스트용 IAM Role (선택적)

## 사용 예제

```hcl
module "iam" {
  source = "../../modules/iam"

  project_name           = "tf-lab"
  env_name              = "dev"
  secrets_arns          = [module.secrets.secret_arn]
  enable_s3_access      = true
  enable_session_manager = false
  create_bastion_role   = true

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
| secrets_arns | List of Secrets Manager ARNs to grant access | list(string) | ["*"] | no |
| enable_s3_access | Enable S3 read access | bool | true | no |
| enable_session_manager | Enable AWS Systems Manager Session Manager | bool | false | no |
| create_bastion_role | Create IAM role for Bastion host | bool | true | no |
| common_tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| ec2_app_role_arn | ARN of EC2 app role |
| ec2_app_role_name | Name of EC2 app role |
| ec2_app_instance_profile_arn | ARN of EC2 app instance profile |
| ec2_app_instance_profile_name | Name of EC2 app instance profile |
| ec2_bastion_instance_profile_name | Name of EC2 bastion instance profile |

## 보안 원칙

### 최소 권한 원칙 (Least Privilege)

1. **Secrets Manager**: 필요한 시크릿만 접근 가능
2. **S3**: 특정 버킷의 읽기 권한만 부여
3. **CloudWatch Logs**: 로그 쓰기 권한만 부여
4. **Bastion**: 최소 권한 (기본적으로 권한 없음)

### Session Manager 사용

`enable_session_manager = true`로 설정 시:
- SSH 포트(22) 없이 EC2 접근 가능
- 모든 세션이 CloudTrail에 기록됨
- Bastion 호스트 불필요

## 참고 자료

- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
