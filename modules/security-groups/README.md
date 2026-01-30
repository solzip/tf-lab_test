# Security Groups Module

VPC 내 리소스들을 위한 보안 그룹을 관리하는 모듈입니다.

## 기능

- ALB Security Group (HTTP/HTTPS 인바운드)
- Bastion Security Group (관리자 IP에서만 SSH)
- App Security Group (ALB와 Bastion에서만 접근)
- DB Security Group (App에서만 접근)

## 보안 원칙

### 최소 권한 원칙 (Least Privilege)

1. **Bastion SG**: 관리자 IP만 SSH 접근 허용 (0.0.0.0/0 금지)
2. **App SG**: ALB에서만 HTTP, Bastion에서만 SSH
3. **DB SG**: App 인스턴스에서만 MySQL 접근

## 사용 예제

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  project_name    = "tf-lab"
  env_name        = "dev"
  vpc_id          = module.vpc.vpc_id
  admin_ssh_cidrs = ["203.0.113.10/32", "198.51.100.20/32"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | - | yes |
| env_name | Environment name | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| admin_ssh_cidrs | CIDR blocks for admin SSH access | list(string) | - | yes (0.0.0.0/0 금지) |

## Outputs

| Name | Description |
|------|-------------|
| alb_sg_id | ALB Security Group ID |
| bastion_sg_id | Bastion Security Group ID |
| app_sg_id | App Security Group ID |
| db_sg_id | DB Security Group ID |

## 보안 규칙

### ALB Security Group
```
Ingress:
  - HTTP (80) from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0

Egress:
  - All traffic to 0.0.0.0/0
```

### Bastion Security Group
```
Ingress:
  - SSH (22) from admin_ssh_cidrs ONLY ⚠️

Egress:
  - All traffic to 0.0.0.0/0
```

### App Security Group
```
Ingress:
  - HTTP (80) from ALB SG
  - SSH (22) from Bastion SG

Egress:
  - All traffic to 0.0.0.0/0
```

### DB Security Group
```
Ingress:
  - MySQL (3306) from App SG

Egress:
  - None (RDS doesn't need outbound)
```

## 관리자 IP 설정 방법

### 1. 현재 IP 확인
```bash
curl ifconfig.me
```

### 2. terraform.tfvars에 추가
```hcl
admin_ssh_cidrs = [
  "203.0.113.10/32",  # 개발자 A
  "198.51.100.20/32", # 개발자 B
]
```

### 3. 긴급 접근이 필요한 경우
임시로 IP를 추가하고, 작업 완료 후 제거:
```bash
terraform apply -var='admin_ssh_cidrs=["YOUR_IP/32"]'
```

## 보안 검증

```bash
# Bastion SG 규칙 확인
aws ec2 describe-security-groups \
  --group-ids <bastion-sg-id> \
  --query 'SecurityGroups[0].IpPermissions'

# 0.0.0.0/0가 없는지 확인
```

## 참고 자료

- [VPC Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Terraform aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
