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
- VPC Flow Logs (네트워크 트래픽 모니터링)

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

  # VPC Flow Logs
  enable_flow_logs         = true
  flow_logs_retention_days = 7
  flow_logs_traffic_type   = "ALL"
}
```

## 입력 변수

### 필수 변수

| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_name | Project name | string | Yes |
| env_name | Environment name | string | Yes |
| vpc_cidr | VPC CIDR block | string | Yes |
| azs | Availability Zones | list(string) | Yes |
| public_subnet_cidrs | Public subnet CIDRs | list(string) | Yes |
| private_app_subnet_cidrs | Private app subnet CIDRs | list(string) | Yes |
| private_db_subnet_cidrs | Private DB subnet CIDRs | list(string) | Yes |

### VPC Flow Logs 변수

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| enable_flow_logs | Enable VPC Flow Logs | bool | true | No |
| flow_logs_retention_days | CloudWatch Logs retention (1-3653 days) | number | 7 | No |
| flow_logs_traffic_type | Traffic type to log (ALL/ACCEPT/REJECT) | string | "ALL" | No |

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
├── Private DB Subnets (Multi-AZ)
└── VPC Flow Logs
    ├── CloudWatch Logs Group
    ├── IAM Role (Flow Logs → CloudWatch)
    └── Flow Log Resource
```

## VPC Flow Logs

VPC Flow Logs는 VPC 네트워크 인터페이스를 통해 전송되는 IP 트래픽에 대한 정보를 수집합니다.

### 사용 사례
- 네트워크 트래픽 분석
- 보안 위협 탐지
- 규정 준수 감사
- 네트워크 문제 해결

### 환경별 보존 기간 권장사항
- **Dev**: 7일 (개발 및 테스트용)
- **Staging**: 14일 (사전 검증용)
- **Prod**: 30일 (보안 감사 및 규정 준수)

### Flow Logs 분석 예제

```bash
# CloudWatch Logs Insights 쿼리 예제
fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, protocol, action
| filter action = "REJECT"
| sort @timestamp desc
| limit 20
```

### 비용
- CloudWatch Logs 스토리지: ~$0.50/GB
- Dev 환경 예상 비용: ~$1-2/월
- Prod 환경 예상 비용: ~$3-5/월

## 참고 자료
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)
