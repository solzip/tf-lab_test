# Plan: Infrastructure Modulization (인프라 모듈화)

**작성일**: 2026-01-30
**작성자**: Claude Code
**Feature ID**: infrastructure-modulization
**PDCA Phase**: Plan
**이전 단계**: [infrastructure-expansion](../../04-report/20260130-infrastructure-expansion.report.md)

---

## 1. 목표 (Objective)

### 1.1 학습 목표

현재 단일 파일로 구성된 Terraform 코드를 **재사용 가능한 모듈**로 분리하여 코드 재사용성과 관리성을 향상시킨다.

**학습 내용**:
- Terraform 모듈의 개념과 구조
- 모듈 입력 변수(variables) 설계
- 모듈 출력(outputs) 정의
- 모듈 간 의존성 관리
- 모듈 버전 관리
- 로컬 모듈 vs 원격 모듈

### 1.2 기술 목표

- VPC 네트워크를 재사용 가능한 모듈로 분리
- 각 모듈이 독립적으로 테스트 가능하도록 구조화
- 환경별(local/dev/prod) 모듈 재사용
- 모듈 문서화 (README.md)

---

## 2. 현재 상태 분석 (As-Is)

### 2.1 현재 파일 구조

```
tf-lab/
├── main.tf                    # VPC, Public Subnet, IGW
├── network-private.tf         # NAT Gateway, Private Subnets
├── security-groups.tf         # 모든 Security Groups
├── compute.tf                 # EC2, ASG, Bastion
├── loadbalancer.tf            # ALB, Target Group
├── database.tf                # RDS
├── variables.tf               # 모든 변수
├── outputs.tf                 # 모든 출력
├── backend.tf                 # S3 Backend
├── providers.localstack.tf    # AWS Provider
└── versions.tf                # 버전 요구사항
```

### 2.2 현재 구조의 문제점

**1. 코드 재사용 불가**
- 다른 프로젝트에서 동일한 VPC 구성을 사용하려면 전체 복사 필요
- 환경별(dev/prod) 다른 설정 적용이 어려움

**2. 변수 관리 복잡**
- 모든 변수가 단일 파일에 집중 (현재 31개)
- 어떤 변수가 어떤 리소스에 사용되는지 추적 어려움

**3. 테스트 어려움**
- 전체를 한 번에 apply 해야 함
- 특정 부분만 테스트 불가능

**4. 의존성 불명확**
- 리소스 간 의존성이 코드 전체에 산재
- 변경 영향 범위 파악 어려움

---

## 3. 목표 상태 (To-Be)

### 3.1 모듈 구조

```
tf-lab/
├── modules/                   # 재사용 가능한 모듈
│   ├── vpc/                   # VPC 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   ├── security-groups/       # Security Groups 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   ├── compute/               # Compute 모듈 (EC2, ASG)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   ├── alb/                   # ALB 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   └── rds/                   # RDS 모듈
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
├── environments/              # 환경별 설정
│   ├── local/
│   │   ├── main.tf           # 모듈 호출
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   │
│   ├── dev/                  # (미래)
│   └── prod/                 # (미래)
│
├── backend.tf                 # (기존 위치 유지 또는 이동)
├── providers.localstack.tf    # (기존 위치 유지 또는 이동)
└── versions.tf                # (기존 위치 유지 또는 이동)
```

### 3.2 모듈 간 의존성

```
VPC 모듈
  ├─> Security Groups 모듈
  ├─> Compute 모듈
  ├─> ALB 모듈
  └─> RDS 모듈
```

**의존성 원칙**:
- VPC가 먼저 생성되어야 함
- 다른 모듈들은 VPC 출력(outputs)을 입력으로 받음
- 모듈 간 직접 참조 최소화 (outputs를 통한 간접 참조)

---

## 4. 구현 범위 (Scope)

### 4.1 Phase 1: VPC 모듈 분리 (우선순위: 높음)

**목표**: VPC 관련 리소스를 재사용 가능한 모듈로 분리

**포함 리소스**:
- [ ] VPC
- [ ] Internet Gateway
- [ ] NAT Gateway + EIP
- [ ] Public Subnets (Multi-AZ)
- [ ] Private App Subnets (Multi-AZ)
- [ ] Private DB Subnets (Multi-AZ)
- [ ] Public Route Table
- [ ] Private Route Table
- [ ] Route Table Associations

**모듈 입력 변수**:
```hcl
- vpc_cidr
- project_name
- env_name
- azs
- public_subnet_cidrs
- private_app_subnet_cidrs
- private_db_subnet_cidrs
```

**모듈 출력**:
```hcl
- vpc_id
- public_subnet_ids
- private_app_subnet_ids
- private_db_subnet_ids
- nat_gateway_id
- nat_eip
```

### 4.2 Phase 2: Security Groups 모듈 (우선순위: 높음)

**목표**: Security Groups를 독립 모듈로 분리

**포함 리소스**:
- [ ] ALB Security Group
- [ ] Bastion Security Group
- [ ] App Security Group
- [ ] DB Security Group
- [ ] 모든 Security Group Rules

**모듈 입력 변수**:
```hcl
- vpc_id
- project_name
- env_name
- admin_ssh_cidrs
```

**모듈 출력**:
```hcl
- alb_sg_id
- bastion_sg_id
- app_sg_id
- db_sg_id
```

### 4.3 Phase 3: Compute 모듈 (우선순위: 중간)

**목표**: EC2, ASG, Bastion을 모듈로 분리

**포함 리소스**:
- [ ] Launch Template
- [ ] Auto Scaling Group
- [ ] Auto Scaling Policy
- [ ] Bastion Instance

**모듈 입력 변수**:
```hcl
- vpc_id
- private_subnet_ids
- public_subnet_ids
- app_sg_id
- bastion_sg_id
- target_group_arn
- ami_id
- instance_type
- asg_min/max/desired
```

**모듈 출력**:
```hcl
- asg_name
- asg_arn
- bastion_instance_id
- bastion_public_ip
```

### 4.4 Phase 4: ALB 모듈 (우선순위: 중간)

**목표**: Application Load Balancer를 모듈로 분리

**포함 리소스**:
- [ ] Application Load Balancer
- [ ] Target Group
- [ ] HTTP Listener

**모듈 입력 변수**:
```hcl
- vpc_id
- public_subnet_ids
- alb_sg_id
- project_name
- env_name
```

**모듈 출력**:
```hcl
- alb_dns_name
- alb_arn
- alb_zone_id
- target_group_arn
```

### 4.5 Phase 5: RDS 모듈 (우선순위: 낮음)

**목표**: RDS를 재사용 가능한 모듈로 분리

**포함 리소스**:
- [ ] DB Subnet Group
- [ ] DB Parameter Group
- [ ] RDS Instance

**모듈 입력 변수**:
```hcl
- vpc_id
- private_db_subnet_ids
- db_sg_id
- db_engine
- db_engine_version
- db_instance_class
- db_name
- db_username
- db_password
- db_multi_az
```

**모듈 출력**:
```hcl
- rds_endpoint
- rds_address
- rds_arn
```

### 4.6 Phase 6: 환경별 구성 (우선순위: 중간)

**목표**: local 환경을 environments/local/로 이동

**작업**:
- [ ] environments/local/ 디렉토리 생성
- [ ] 모듈 호출 코드 작성 (main.tf)
- [ ] 환경별 변수 정의
- [ ] backend.hcl, terraform.tfvars 이동

---

## 5. 모듈 설계 원칙

### 5.1 단일 책임 원칙 (Single Responsibility)

각 모듈은 하나의 명확한 목적만 가져야 함:
- VPC 모듈: 네트워크 구성만
- Compute 모듈: 컴퓨팅 리소스만
- RDS 모듈: 데이터베이스만

### 5.2 느슨한 결합 (Loose Coupling)

모듈 간 직접 참조 최소화:
```hcl
# Bad: 직접 참조
resource "aws_instance" "app" {
  subnet_id = module.vpc.private_subnet_ids[0]  # 모듈 내부 참조
}

# Good: 변수를 통한 간접 참조
resource "aws_instance" "app" {
  subnet_id = var.subnet_id  # 변수로 받음
}
```

### 5.3 명확한 인터페이스

**입력(Variables)**:
- 필수 변수와 선택 변수 명확히 구분
- 기본값(default) 제공
- 설명(description) 필수

**출력(Outputs)**:
- 다른 모듈에서 필요한 값만 노출
- 민감 정보는 sensitive = true

### 5.4 문서화

각 모듈에 README.md 포함:
- 모듈 목적
- 입력 변수 설명
- 출력 값 설명
- 사용 예시
- 요구사항

---

## 6. 마이그레이션 전략

### 6.1 점진적 마이그레이션

**단계별 접근**:
1. VPC 모듈부터 시작 (기반)
2. 의존성이 적은 모듈부터 분리
3. 각 모듈마다 테스트 후 다음 단계 진행

### 6.2 상태 파일 관리

**중요**: Terraform State를 유지하면서 리팩토링

**방법 1: terraform state mv** (권장)
```bash
# 리소스를 모듈로 이동
terraform state mv aws_vpc.main module.vpc.aws_vpc.main
```

**방법 2: 재생성**
```bash
# 기존 리소스 삭제 후 재생성 (LocalStack은 OK)
terraform destroy -target=aws_vpc.main
terraform apply
```

### 6.3 검증 절차

각 Phase마다:
1. 모듈 코드 작성
2. terraform init (모듈 다운로드)
3. terraform validate
4. terraform plan (변경 사항 확인)
5. terraform apply (실제 적용)
6. 기능 검증

---

## 7. 파일 구조 상세

### 7.1 VPC 모듈 예시

```
modules/vpc/
├── main.tf              # VPC, Subnets, Route Tables
├── variables.tf         # 입력 변수
├── outputs.tf           # 출력 값
└── README.md            # 모듈 문서
```

**main.tf**:
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  # ...
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  # ...
}
```

**variables.tf**:
```hcl
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}
```

**outputs.tf**:
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}
```

### 7.2 환경별 설정 예시

```
environments/local/
├── main.tf              # 모듈 호출
├── variables.tf         # 환경별 변수 정의
├── outputs.tf           # 환경별 출력
├── backend.hcl          # Backend 설정
└── terraform.tfvars     # 변수 값
```

**main.tf** (모듈 호출):
```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr                = var.vpc_cidr
  project_name            = var.project_name
  env_name                = var.env_name
  azs                     = var.azs
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id           = module.vpc.vpc_id
  project_name     = var.project_name
  env_name         = var.env_name
  admin_ssh_cidrs  = var.admin_ssh_cidrs
}
```

---

## 8. 리스크 및 제약사항

### 8.1 리스크

| 리스크 | 영향 | 확률 | 대응 방안 |
|--------|------|------|----------|
| State 파일 손상 | 높음 | 낮음 | 백업 후 작업, state mv 사용 |
| 모듈 의존성 오류 | 중간 | 중간 | 순차적 마이그레이션 |
| 변수 누락 | 낮음 | 중간 | terraform validate로 검증 |
| 복잡도 증가 (초기) | 중간 | 높음 | 문서화 철저히 |

### 8.2 LocalStack 제약사항

- State 관리는 동일하게 작동
- 모듈 구조는 실제 AWS와 동일
- 학습 목적으로는 충분

---

## 9. 성공 기준 (Success Criteria)

### 9.1 기능 요구사항

- [ ] 각 모듈이 독립적으로 테스트 가능
- [ ] 모듈 재사용 가능 (다른 환경에서 동일 모듈 사용)
- [ ] 기존 리소스가 모듈 분리 후에도 정상 작동
- [ ] terraform plan 결과 변경사항 없음 (리팩토링만)

### 9.2 코드 품질

- [ ] 모든 모듈에 README.md 포함
- [ ] 변수에 description 필수
- [ ] 출력에 description 필수
- [ ] terraform validate 통과
- [ ] terraform fmt 적용

### 9.3 문서화

- [ ] 각 모듈 사용법 문서화
- [ ] 환경별 배포 가이드 작성
- [ ] 모듈 간 의존성 다이어그램

---

## 10. 일정 계획

| Phase | 작업 내용 | 예상 시간 | 우선순위 |
|-------|----------|----------|---------|
| Phase 1 | VPC 모듈 분리 | 1시간 | 높음 |
| Phase 2 | Security Groups 모듈 | 30분 | 높음 |
| Phase 3 | Compute 모듈 | 40분 | 중간 |
| Phase 4 | ALB 모듈 | 30분 | 중간 |
| Phase 5 | RDS 모듈 | 30분 | 낮음 |
| Phase 6 | 환경별 구성 | 30분 | 중간 |
| 문서화 | README.md 작성 | 30분 | 높음 |
| 검증 | 테스트 및 검증 | 30분 | 높음 |

**총 예상**: 4-5시간

---

## 11. 학습 포인트

### 11.1 Terraform 모듈 개념

- 모듈이란 무엇인가?
- 로컬 모듈 vs 원격 모듈
- 모듈 버전 관리

### 11.2 모듈 설계 패턴

- 입력 변수 설계 원칙
- 출력 값 설계 원칙
- 모듈 간 의존성 관리

### 11.3 코드 재사용성

- DRY (Don't Repeat Yourself) 원칙
- 환경별 설정 분리
- 모듈 조합 (Composition)

---

## 12. 다음 단계

1. **Design 문서 작성** (`/pdca design infrastructure-modulization`)
   - 각 모듈의 상세 설계
   - 변수/출력 상세 정의
   - 모듈 간 데이터 흐름

2. **Do (구현)**
   - Phase별 순차 구현
   - 각 Phase마다 검증

3. **Check (검증)**
   - Gap Analysis
   - terraform plan으로 변경사항 확인

4. **Act (개선)**
   - 문서 보완
   - 코드 최적화

---

## 13. 참고 자료

- [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)
- [Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)
- [Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

---

**Plan 작성 완료**: 2026-01-30
**다음 단계**: Design 문서 작성 (`/pdca design infrastructure-modulization`)
