# Plan: Infrastructure Expansion (인프라 확장)

**작성일**: 2026-01-30
**작성자**: Claude Code
**Feature ID**: infrastructure-expansion
**PDCA Phase**: Plan

---

## 1. 목표 (Objective)

현재 Public Subnet만 구성된 기본 VPC 인프라를 확장하여 실무에 가까운 3-Tier 아키텍처를 학습한다.

### 학습 목표
- Private Subnet과 NAT Gateway를 통한 보안 네트워킹 이해
- EC2 인스턴스 배포 및 Auto Scaling 학습
- Load Balancer (ALB/NLB) 구성 방법 습득
- RDS Multi-AZ 고가용성 데이터베이스 구성

### 기술 목표
- Terraform 모듈 간 의존성 관리
- Data Source 활용
- Count/For_each를 사용한 동적 리소스 생성
- LocalStack 제약사항 내에서 최대한 실제 AWS와 유사한 구성

---

## 2. 현재 상태 분석 (As-Is)

### 2.1 기존 인프라
```
VPC (10.10.0.0/16)
├── Internet Gateway
├── Public Subnets (2개)
│   ├── 10.10.1.0/24 (ap-northeast-2a)
│   └── 10.10.2.0/24 (ap-northeast-2c)
├── Public Route Table
│   └── 0.0.0.0/0 → IGW
└── Security Group (web)
    ├── HTTP(80), SSH(22)
    └── Egress: All
```

### 2.2 제약사항
- Public Subnet만 존재 (Private 없음)
- 컴퓨팅 리소스 없음 (EC2, RDS 미배포)
- Load Balancer 없음
- NAT Gateway 없음

### 2.3 LocalStack 제약사항 확인
- EC2: 제한적 지원 (기본 인스턴스 생성 가능)
- NAT Gateway: 모의(mock) 지원
- ALB/NLB: 제한적 지원
- RDS: 제한적 지원 (Community Edition 한계)

---

## 3. 목표 상태 (To-Be)

### 3.1 3-Tier 아키텍처
```
VPC (10.10.0.0/16)
├── Internet Gateway
├── NAT Gateway (Public Subnet에 배치)
│
├── Public Tier (Web Layer)
│   ├── Public Subnets (Multi-AZ)
│   │   ├── 10.10.1.0/24 (ap-northeast-2a)
│   │   └── 10.10.2.0/24 (ap-northeast-2c)
│   ├── Application Load Balancer
│   └── Bastion Host (SSH 접근용)
│
├── Private Tier (Application Layer)
│   ├── Private App Subnets (Multi-AZ)
│   │   ├── 10.10.11.0/24 (ap-northeast-2a)
│   │   └── 10.10.12.0/24 (ap-northeast-2c)
│   ├── EC2 Auto Scaling Group
│   └── Private Route Table → NAT Gateway
│
└── Data Tier (Database Layer)
    ├── Private DB Subnets (Multi-AZ)
    │   ├── 10.10.21.0/24 (ap-northeast-2a)
    │   └── 10.10.22.0/24 (ap-northeast-2c)
    ├── RDS Instance (Multi-AZ)
    └── DB Subnet Group
```

### 3.2 보안 구성
```
Security Groups:
├── ALB-SG (80/443 from 0.0.0.0/0)
├── Bastion-SG (22 from Admin CIDR)
├── App-SG (80 from ALB-SG, 22 from Bastion-SG)
└── DB-SG (3306/5432 from App-SG only)
```

---

## 4. 구현 범위 (Scope)

### 4.1 Phase 1: 네트워크 확장 (우선순위: 높음)
- [ ] Private Subnet 생성 (App용 2개, DB용 2개)
- [ ] NAT Gateway 생성 및 EIP 할당
- [ ] Private Route Table 생성 및 연결
- [ ] CIDR 설계 문서화

### 4.2 Phase 2: 컴퓨팅 리소스 (우선순위: 높음)
- [ ] EC2 Launch Template 정의
- [ ] Auto Scaling Group 구성
- [ ] Bastion Host 배포 (Public Subnet)
- [ ] User Data 스크립트 작성

### 4.3 Phase 3: Load Balancer (우선순위: 중간)
- [ ] Application Load Balancer 생성
- [ ] Target Group 구성
- [ ] Health Check 설정
- [ ] ALB → EC2 연결

### 4.4 Phase 4: 데이터베이스 (우선순위: 중간)
- [ ] DB Subnet Group 생성
- [ ] RDS Parameter Group
- [ ] RDS Instance (Multi-AZ)
- [ ] 백업 및 유지보수 윈도우 설정

### 4.5 Phase 5: 보안 강화 (우선순위: 낮음)
- [ ] Security Group 세분화
- [ ] NACL 추가 (선택)
- [ ] SSH 키 관리 개선
- [ ] IAM Role for EC2

---

## 5. 기술 스택

| 카테고리 | 기술 | 용도 |
|---------|------|------|
| 네트워킹 | VPC, Subnet, NAT Gateway | 네트워크 격리 |
| 컴퓨팅 | EC2, Auto Scaling | 애플리케이션 실행 |
| 로드밸런싱 | ALB | 트래픽 분산 |
| 데이터베이스 | RDS (MySQL/PostgreSQL) | 데이터 저장 |
| 보안 | Security Groups, NACL | 접근 제어 |
| IaC | Terraform 1.5+ | 인프라 코드화 |

---

## 6. 변수 설계

### 6.1 추가 변수 (variables.tf)
```hcl
# Private App Subnet CIDR
variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.11.0/24", "10.10.12.0/24"]
}

# Private DB Subnet CIDR
variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.21.0/24", "10.10.22.0/24"]
}

# EC2 인스턴스 타입
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# RDS 설정
variable "db_engine" {
  description = "Database engine (mysql/postgres)"
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# Auto Scaling 설정
variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}
```

---

## 7. 파일 구조 계획

```
tf-lab/
├── main.tf                        # 기존 VPC/Public Subnet
├── network-private.tf             # (신규) Private Subnet, NAT Gateway
├── compute.tf                     # (신규) EC2, ASG, Launch Template
├── loadbalancer.tf                # (신규) ALB, Target Group
├── database.tf                    # (신규) RDS, DB Subnet Group
├── security-groups.tf             # (신규) 모든 SG 통합 관리
├── outputs.tf                     # 기존 + 신규 리소스 output 추가
├── variables.tf                   # 기존 + 신규 변수 추가
└── env/local/terraform.tfvars     # 신규 변수값 추가
```

---

## 8. 리스크 및 제약사항

### 8.1 LocalStack 제약사항
| 리소스 | LocalStack 지원 | 대응 방안 |
|--------|----------------|----------|
| NAT Gateway | Mock 지원 | 생성은 되지만 실제 NAT 기능은 제한적 |
| ALB | 제한적 | Health Check는 간소화 |
| RDS | 제한적 | 실제 DB 엔진 대신 모의 응답 |
| Auto Scaling | 제한적 | 인스턴스 생성은 되지만 스케일링 이벤트는 제한적 |

### 8.2 비용 (실제 AWS 배포 시)
- NAT Gateway: ~$0.045/시간 + 데이터 전송
- ALB: ~$0.0225/시간 + LCU
- RDS Multi-AZ: 단일 AZ의 2배
- EC2: 인스턴스 타입에 따라

### 8.3 학습 난이도
- **초급**: VPC, Subnet, Route Table
- **중급**: NAT Gateway, Security Group 설계
- **중급+**: ALB, Auto Scaling
- **고급**: RDS Multi-AZ, 보안 최적화

---

## 9. 성공 기준 (Success Criteria)

### 9.1 기능 요구사항
- [ ] Private Subnet에서 NAT Gateway를 통한 외부 통신 가능
- [ ] ALB를 통한 EC2 접근 가능
- [ ] Bastion을 통한 Private EC2 SSH 접근 가능
- [ ] EC2에서 RDS 연결 가능
- [ ] Security Group으로 계층 간 접근 제어

### 9.2 코드 품질
- [ ] 모든 리소스에 적절한 주석 (한글)
- [ ] 변수화로 하드코딩 제거
- [ ] terraform validate 통과
- [ ] terraform fmt 적용
- [ ] 네이밍 컨벤션 준수 (`{project}-{env}-{resource}`)

### 9.3 문서화
- [ ] 아키텍처 다이어그램 (Mermaid)
- [ ] 각 리소스의 용도 설명
- [ ] 실행 명령어 가이드 업데이트
- [ ] 트러블슈팅 가이드

---

## 10. 일정 계획

| Phase | 작업 내용 | 예상 시간 | 우선순위 |
|-------|----------|----------|---------|
| Phase 1 | 네트워크 확장 | 1-2시간 | 높음 |
| Phase 2 | 컴퓨팅 리소스 | 2-3시간 | 높음 |
| Phase 3 | Load Balancer | 1-2시간 | 중간 |
| Phase 4 | 데이터베이스 | 1-2시간 | 중간 |
| Phase 5 | 보안 강화 | 1시간 | 낮음 |

**총 예상**: 6-10시간

---

## 11. 다음 단계

1. **Design 문서 작성** (`/pdca design infrastructure-expansion`)
   - 상세 리소스 설계
   - Terraform 코드 구조 설계
   - 보안 그룹 규칙 상세 설계

2. **Do (구현)**
   - Phase별 순차 구현
   - 각 Phase마다 plan → apply → 검증

3. **Check (검증)**
   - Gap Analysis 실행
   - 설계와 구현 비교

4. **Act (개선)**
   - Gap 해소
   - 코드 리팩토링

---

## 12. 참고 자료

- [Terraform AWS Provider - VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [LocalStack EC2 Documentation](https://docs.localstack.cloud/user-guide/aws/ec2/)
- [Terraform Count vs For_each](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

---

**Plan 작성 완료**: 2026-01-30
**다음 단계**: Design 문서 작성 (`20260130-infrastructure-expansion.design.md`)
