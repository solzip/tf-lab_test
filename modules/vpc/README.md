# VPC Module

## 목적

AWS VPC 네트워크 인프라를 생성합니다:
- VPC with DNS support
- Internet Gateway
- NAT Gateway (single AZ)
- Public Subnets (Multi-AZ)
- Private App Subnets (Multi-AZ)
- Private DB Subnets (Multi-AZ)
- Route Tables

## 사용법

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name             = "my-project"
  env_name                 = "local"
  vpc_cidr                 = "10.10.0.0/16"
  azs                      = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs      = ["10.10.1.0/24", "10.10.2.0/24"]
  private_app_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
  private_db_subnet_cidrs  = ["10.10.21.0/24", "10.10.22.0/24"]
}
```

## 입력 변수

| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_name | Project name | string | Yes |
| env_name | Environment name | string | Yes |
| vpc_cidr | VPC CIDR block | string | Yes |
| azs | Availability Zones | list(string) | Yes |
| public_subnet_cidrs | Public subnet CIDRs | list(string) | Yes |
| private_app_subnet_cidrs | Private app subnet CIDRs | list(string) | Yes |
| private_db_subnet_cidrs | Private DB subnet CIDRs | list(string) | Yes |

## 출력

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | Public subnet IDs |
| private_app_subnet_ids | Private app subnet IDs |
| private_db_subnet_ids | Private DB subnet IDs |
| nat_gateway_id | NAT Gateway ID |
| nat_eip | NAT Gateway Elastic IP |
| internet_gateway_id | Internet Gateway ID |

## 요구사항

- Terraform >= 1.5.0
- AWS Provider ~> 5.100

## 아키텍처

```
VPC (10.10.0.0/16)
├── Internet Gateway
├── NAT Gateway (in Public Subnet)
├── Public Subnets (Multi-AZ)
├── Private App Subnets (Multi-AZ)
└── Private DB Subnets (Multi-AZ)
```
