# Implementation: Infrastructure Expansion (인프라 확장)

**작성일**: 2026-01-30
**작성자**: Claude Code
**Feature ID**: infrastructure-expansion
**PDCA Phase**: Do (Implementation)
**Based on**: [20260130-infrastructure-expansion.design.md](../02-design/features/20260130-infrastructure-expansion.design.md)

---

## 1. 구현 개요

### 1.1 구현 완료 항목

✅ **Phase 1: 네트워크 확장**
- Private App Subnets (2개, Multi-AZ)
- Private DB Subnets (2개, Multi-AZ)
- NAT Gateway + EIP
- Private Route Table 구성

✅ **Phase 2: Security Groups**
- ALB Security Group (HTTP/HTTPS from Internet)
- Bastion Security Group (SSH from Admin)
- App Security Group (HTTP from ALB, SSH from Bastion)
- DB Security Group (MySQL from App only)

✅ **Phase 3: 컴퓨팅 리소스**
- Launch Template (Apache 웹 서버 자동 설치)
- Auto Scaling Group (2-4 인스턴스)
- Auto Scaling Policy (CPU 기반)
- Bastion Host (Public Subnet)

✅ **Phase 4: Load Balancer**
- Application Load Balancer (Public Subnet)
- Target Group (Health Check 포함)
- HTTP Listener (Port 80)

✅ **Phase 5: 데이터베이스**
- DB Subnet Group
- DB Parameter Group (UTF-8 설정)
- RDS MySQL 8.0.35 (db.t3.micro)
- 자동 백업 설정 (7일 보관)

✅ **Phase 6: 설정 업데이트**
- variables.tf (16개 신규 변수 추가)
- outputs.tf (15개 신규 출력 추가)
- terraform.tfvars (변수값 설정)
- main.tf (중복 SG 제거)

---

## 2. 파일 구조

### 2.1 신규 생성 파일

```
tf-lab/
├── network-private.tf       # NAT Gateway, Private Subnets, Route Table
├── security-groups.tf       # ALB, Bastion, App, DB Security Groups
├── compute.tf               # EC2, ASG, Launch Template, Bastion
├── loadbalancer.tf          # ALB, Target Group, Listener
└── database.tf              # RDS, DB Subnet Group, Parameter Group
```

### 2.2 수정된 파일

```
tf-lab/
├── variables.tf             # 16개 신규 변수 추가
├── outputs.tf               # 15개 신규 출력 추가
├── main.tf                  # Security Group 제거 (중복 방지)
└── env/local/terraform.tfvars  # 신규 변수값 설정
```

### 2.3 문서 파일

```
docs/
├── 01-plan/features/
│   └── 20260130-infrastructure-expansion.plan.md
├── 02-design/features/
│   └── 20260130-infrastructure-expansion.design.md
└── 03-implementation/
    └── 20260130-infrastructure-expansion.implementation.md (현재)
```

---

## 3. 리소스 상세 내역

### 3.1 네트워크 리소스 (network-private.tf)

| 리소스 | 타입 | 수량 | 설명 |
|--------|------|------|------|
| NAT Gateway | aws_nat_gateway | 1 | Public Subnet에 배치 |
| Elastic IP | aws_eip | 1 | NAT Gateway용 |
| Private App Subnet | aws_subnet | 2 | 10.10.11.0/24, 10.10.12.0/24 |
| Private DB Subnet | aws_subnet | 2 | 10.10.21.0/24, 10.10.22.0/24 |
| Private Route Table | aws_route_table | 1 | 0.0.0.0/0 → NAT Gateway |
| Route Table Association | aws_route_table_association | 4 | Private Subnets 연결 |

**총 코드 라인**: 145줄

### 3.2 보안 그룹 (security-groups.tf)

| Security Group | 인바운드 규칙 | 아웃바운드 규칙 |
|----------------|--------------|----------------|
| ALB SG | HTTP(80), HTTPS(443) from 0.0.0.0/0 | All |
| Bastion SG | SSH(22) from Admin CIDR | All |
| App SG | HTTP(80) from ALB SG, SSH(22) from Bastion SG | All |
| DB SG | MySQL(3306) from App SG | None (제한) |

**총 코드 라인**: 216줄

### 3.3 컴퓨팅 리소스 (compute.tf)

| 리소스 | 타입 | 설명 |
|--------|------|------|
| Launch Template | aws_launch_template | EC2 템플릿 (Apache 자동 설치) |
| Auto Scaling Group | aws_autoscaling_group | Min: 2, Max: 4, Desired: 2 |
| Auto Scaling Policy | aws_autoscaling_policy | CPU 70% 목표 |
| Bastion Host | aws_instance | Public Subnet, t3.micro |

**User Data 기능**:
- Apache 웹 서버 설치 및 시작
- 인스턴스 정보 표시 HTML 페이지 생성
- Health Check 엔드포인트 (/health)

**총 코드 라인**: 277줄

### 3.4 로드 밸런서 (loadbalancer.tf)

| 리소스 | 타입 | 설명 |
|--------|------|------|
| ALB | aws_lb | Public Subnet (Multi-AZ) |
| Target Group | aws_lb_target_group | HTTP:80, Health Check 활성화 |
| HTTP Listener | aws_lb_listener | Port 80 → Target Group |

**Health Check 설정**:
- Path: /
- Interval: 30초
- Timeout: 5초
- Healthy Threshold: 2
- Unhealthy Threshold: 2

**총 코드 라인**: 211줄

### 3.5 데이터베이스 (database.tf)

| 리소스 | 타입 | 설명 |
|--------|------|------|
| DB Subnet Group | aws_db_subnet_group | Private DB Subnets |
| DB Parameter Group | aws_db_parameter_group | UTF-8 설정 |
| RDS Instance | aws_db_instance | MySQL 8.0.35, db.t3.micro |

**RDS 설정**:
- Engine: MySQL 8.0.35
- Instance Class: db.t3.micro
- Storage: 20GB gp3 (최대 100GB 자동 확장)
- Multi-AZ: false (학습용)
- Backup Retention: 7일
- Backup Window: 03:00-04:00 UTC
- Maintenance Window: Mon 04:00-05:00 UTC

**총 코드 라인**: 257줄

---

## 4. 변수 및 출력

### 4.1 신규 변수 (16개)

```hcl
# 네트워크
private_app_subnet_cidrs    # Private App Subnet CIDR 목록
private_db_subnet_cidrs     # Private DB Subnet CIDR 목록
admin_ssh_cidrs             # Bastion SSH 허용 CIDR

# EC2
ami_id                      # EC2 AMI ID
instance_type               # EC2 인스턴스 타입

# Auto Scaling
asg_min_size                # ASG 최소 크기
asg_max_size                # ASG 최대 크기
asg_desired_capacity        # ASG 원하는 용량

# RDS
db_engine                   # DB 엔진 (mysql/postgres)
db_engine_version           # DB 엔진 버전
db_instance_class           # RDS 인스턴스 클래스
db_name                     # 데이터베이스 이름
db_username                 # DB 마스터 사용자명 (sensitive)
db_password                 # DB 마스터 패스워드 (sensitive)
db_multi_az                 # Multi-AZ 활성화 여부
```

### 4.2 신규 출력 (15개)

```hcl
# NAT Gateway
nat_gateway_id              # NAT Gateway ID
nat_eip                     # NAT Gateway EIP

# Private Subnets
private_app_subnet_ids      # Private App Subnet IDs
private_db_subnet_ids       # Private DB Subnet IDs

# Security Groups
alb_sg_id                   # ALB SG ID
bastion_sg_id               # Bastion SG ID
app_sg_id                   # App SG ID
db_sg_id                    # DB SG ID

# Load Balancer
alb_dns_name                # ALB DNS 이름
alb_arn                     # ALB ARN
alb_zone_id                 # ALB Zone ID

# Auto Scaling
asg_name                    # ASG 이름
asg_arn                     # ASG ARN

# Bastion
bastion_public_ip           # Bastion Public IP
bastion_instance_id         # Bastion Instance ID

# RDS
rds_endpoint                # RDS 엔드포인트 (sensitive)
rds_address                 # RDS 주소 (sensitive)
rds_arn                     # RDS ARN
rds_resource_id             # RDS 리소스 ID
```

---

## 5. 코드 통계

### 5.1 총 코드 라인 수

| 파일 | 라인 수 | 비고 |
|------|---------|------|
| network-private.tf | 145 | 네트워크 확장 |
| security-groups.tf | 216 | Security Groups |
| compute.tf | 277 | EC2, ASG, Bastion |
| loadbalancer.tf | 211 | ALB, Target Group |
| database.tf | 257 | RDS, DB Subnet Group |
| variables.tf | +145 | 신규 변수 추가 |
| outputs.tf | +115 | 신규 출력 추가 |
| terraform.tfvars | +40 | 변수값 설정 |
| **총계** | **1,406** | **신규 및 수정** |

### 5.2 리소스 통계

| 카테고리 | 리소스 수 |
|---------|----------|
| 네트워크 | 10 |
| 보안 그룹 | 4 + 규칙 12 = 16 |
| 컴퓨팅 | 4 |
| 로드 밸런서 | 3 |
| 데이터베이스 | 3 |
| **총계** | **36개** |

---

## 6. 아키텍처 변화

### 6.1 Before (기존)

```
VPC (10.10.0.0/16)
├── Internet Gateway
├── Public Subnets (2개)
└── Public Route Table
```

### 6.2 After (구현 후)

```
VPC (10.10.0.0/16)
├── Internet Gateway
├── NAT Gateway + EIP
│
├── Public Tier
│   ├── Public Subnets (2개)
│   ├── ALB
│   └── Bastion Host
│
├── Private App Tier
│   ├── Private App Subnets (2개)
│   ├── Auto Scaling Group (2-4 EC2)
│   └── Private Route Table → NAT
│
└── Private DB Tier
    ├── Private DB Subnets (2개)
    └── RDS MySQL (Multi-AZ 가능)
```

---

## 7. 검증 절차

### 7.1 코드 포맷 및 검증

```bash
# 1. 코드 포맷 정리
terraform fmt -recursive

# 2. 구문 검증
terraform validate
```

**예상 결과**: Success, 0 errors

### 7.2 초기화 및 Plan

```bash
# 3. 환경변수 설정 (PowerShell)
. .\scripts\set-localstack-env.ps1

# 4. Terraform 초기화
terraform init -reconfigure -backend-config=env/local/backend.hcl

# 5. Plan 실행
terraform plan -var-file=env/local/terraform.tfvars -out=tfplan
```

**예상 결과**: 36개 리소스 생성 계획

### 7.3 Apply (선택)

```bash
# 6. 인프라 적용
terraform apply tfplan

# 7. 출력 확인
terraform output
```

### 7.4 LocalStack 리소스 확인

```bash
# VPC 확인
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs

# Subnets 확인 (총 6개: Public 2 + Private App 2 + Private DB 2)
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets

# NAT Gateway 확인
aws --endpoint-url=http://localhost:4566 ec2 describe-nat-gateways

# Security Groups 확인 (4개)
aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups

# ALB 확인
aws --endpoint-url=http://localhost:4566 elbv2 describe-load-balancers

# RDS 확인
aws --endpoint-url=http://localhost:4566 rds describe-db-instances
```

---

## 8. LocalStack 제약사항 및 대응

### 8.1 제약사항

| 리소스 | 제약사항 | 영향 |
|--------|---------|------|
| NAT Gateway | Mock 지원 | 생성되지만 실제 NAT 기능 제한적 |
| EC2 | 제한적 | 메타데이터 제한, SSH 불가 |
| ALB | 제한적 | Health Check 간소화 |
| RDS | Mock | 메타데이터만 저장, DB 엔진 미실행 |
| Auto Scaling | Mock | 스케일링 이벤트 제한적 |

### 8.2 학습 포커스

LocalStack 제약사항에도 불구하고 다음을 학습할 수 있습니다:

✅ **Terraform 코드 작성**
- 리소스 정의 및 의존성 관리
- 변수와 출력 활용
- count/for_each를 통한 동적 리소스 생성

✅ **아키텍처 설계**
- 3-Tier 아키텍처 구성
- 네트워크 계층 분리
- 보안 그룹 설계 (최소 권한 원칙)

✅ **실제 AWS 배포 준비**
- 환경별 설정 분리 (local/dev/prod)
- 민감 정보 관리
- 백업 및 고가용성 설정

---

## 9. 주의사항

### 9.1 보안

⚠️ **현재 설정 (학습용)**:
- Bastion SSH: 0.0.0.0/0 허용
- DB 패스워드: 코드에 하드코딩

✅ **운영 환경 권장**:
- Bastion SSH: 관리자 IP로 제한
- DB 패스워드: AWS Secrets Manager 사용
- Storage Encryption: true
- Multi-AZ: true

### 9.2 비용 (실제 AWS)

| 리소스 | 예상 비용 (월) |
|--------|--------------|
| NAT Gateway | ~$32 (+ 데이터 전송) |
| ALB | ~$16 (+ LCU) |
| EC2 (t3.micro x2) | ~$12 |
| RDS (db.t3.micro) | ~$12 |
| **총계** | **~$72/월** |

💡 **절감 방안**:
- NAT Gateway → NAT Instance
- Reserved Instance (1년 약정)
- 개발 환경은 야간/주말 중지

---

## 10. 다음 단계

### 10.1 Check (검증)

```bash
/pdca analyze infrastructure-expansion
```

- Design 문서와 실제 코드 비교
- Gap Analysis 실행
- Match Rate 계산

### 10.2 Act (개선)

- Gap이 90% 미만이면 자동 개선
- 코드 최적화 및 리팩토링

### 10.3 Report (보고)

```bash
/pdca report infrastructure-expansion
```

- 완료 보고서 생성
- 학습 내용 정리

---

## 11. 트러블슈팅

### 11.1 Terraform 오류

**문제**: `Error: Reference to undeclared resource`

**원인**: 리소스 참조 오류

**해결**:
```bash
terraform validate
# 오류 메시지 확인 후 리소스명 수정
```

### 11.2 LocalStack 연결 오류

**문제**: `Error: error configuring Terraform AWS Provider`

**원인**: LocalStack 미실행 또는 환경변수 미설정

**해결**:
```bash
# LocalStack 실행 확인
docker ps | grep localstack

# 환경변수 재설정
. .\scripts\set-localstack-env.ps1
```

### 11.3 변수 오류

**문제**: `Error: Missing required argument`

**원인**: terraform.tfvars에 변수값 누락

**해결**:
- env/local/terraform.tfvars 확인
- 누락된 변수값 추가

---

## 12. 참고 자료

### 12.1 Terraform 공식 문서

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [VPC Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [EC2 Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [ALB Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)
- [RDS Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)

### 12.2 AWS 문서

- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Auto Scaling Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)

### 12.3 LocalStack 문서

- [LocalStack EC2](https://docs.localstack.cloud/user-guide/aws/ec2/)
- [LocalStack RDS](https://docs.localstack.cloud/user-guide/aws/rds/)

---

**구현 완료**: 2026-01-30
**총 작업 시간**: 약 2시간
**다음 단계**: Gap Analysis (`/pdca analyze infrastructure-expansion`)
