# Security Groups Module

## 목적

계층별 Security Groups 생성:
- ALB Security Group (HTTP/HTTPS from Internet)
- Bastion Security Group (SSH from Admin)
- App Security Group (HTTP from ALB, SSH from Bastion)
- DB Security Group (MySQL from App)

## 사용법

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  project_name    = "my-project"
  env_name        = "local"
  vpc_id          = module.vpc.vpc_id
  admin_ssh_cidrs = ["1.2.3.4/32"]
}
```

## 입력 변수

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | - | Yes |
| env_name | Environment name | string | - | Yes |
| vpc_id | VPC ID | string | - | Yes |
| admin_ssh_cidrs | SSH CIDR blocks | list(string) | ["0.0.0.0/0"] | No |

## 출력

| Name | Description |
|------|-------------|
| alb_sg_id | ALB Security Group ID |
| bastion_sg_id | Bastion Security Group ID |
| app_sg_id | Application Security Group ID |
| db_sg_id | Database Security Group ID |

## Security Group Rules

### ALB SG
- Ingress: HTTP(80), HTTPS(443) from 0.0.0.0/0
- Egress: All

### Bastion SG
- Ingress: SSH(22) from Admin CIDR
- Egress: All

### App SG
- Ingress: HTTP(80) from ALB SG, SSH(22) from Bastion SG
- Egress: All

### DB SG
- Ingress: MySQL(3306) from App SG
- Egress: None (restricted)
