# Plan: Multi-Environment Setup

**작성일**: 2026-01-30
**작성자**: Claude Code
**Feature ID**: multi-environment-setup
**PDCA Phase**: Plan
**이전 단계**: [Step 3 - LocalStack Deployment](20260130-localstack-deployment.plan.md)

---

## 1. 목표 (Objectives)

### 1.1 주요 목표
개발(Dev), 스테이징(Staging), 프로덕션(Production) 환경을 분리하고, 각 환경별로 독립적인 인프라를 관리할 수 있는 멀티 환경 구성을 구축한다.

### 1.2 학습 목표
- Terraform 멀티 환경 구성 전략 학습 (Workspace vs Directory-based)
- 환경별 변수 관리 및 오버라이드 메커니즘 이해
- 환경별 Backend 분리 및 State 격리 방법 습득
- 환경별 리소스 네이밍 컨벤션 및 태깅 전략 이해
- 환경별 배포 자동화 및 안전한 배포 전략 수립
- 환경별 인프라 차이 관리 (리소스 크기, 개수, 설정 등)

### 1.3 성공 기준
- [ ] Dev, Staging, Production 3개 환경 디렉토리 구성 완료
- [ ] 각 환경별 독립적인 `backend.hcl` 설정 파일 구성
- [ ] 환경별 `terraform.tfvars` 파일로 변수 관리
- [ ] 환경별 리소스 네이밍 컨벤션 적용 (예: `tf-lab-dev-vpc`)
- [ ] 환경별 태그 자동 적용 (Environment: dev/staging/prod)
- [ ] Dev 환경에 `terraform apply` 성공
- [ ] Staging 환경에 `terraform apply` 성공
- [ ] 환경 간 State 완전 격리 확인
- [ ] 환경별 배포 스크립트 작성 및 검증
- [ ] 환경별 인프라 차이 문서화 (리소스 크기, 개수 등)

---

## 2. 현황 분석 (Current State)

### 2.1 완료된 사항
✅ **Step 1**: 3-Tier 인프라 설계 및 구현 (67 resources)
✅ **Step 2**: 모듈화 완료 (5 modules, 43 resources)
✅ **Step 3**: LocalStack 배포 및 검증 (35/43 resources, 81.4% 성공)
✅ **PDCA 문서**: 각 단계별 Plan, Design, Validation, Report 완성
✅ **Git 커밋**: 모든 변경사항 버전 관리

### 2.2 현재 상태
```
현재 환경 구성:
environments/
└── local/                    ✅ LocalStack 전용 환경
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars
    ├── backend.tf
    ├── backend.hcl
    ├── providers.tf
    └── user-data.sh

문제점:
❌ 단일 환경만 존재 (local만 있음)
❌ Dev, Staging, Production 환경 분리 안 됨
❌ 환경별 변수 관리 체계 없음
❌ 환경별 Backend State 격리 안 됨
❌ 환경별 리소스 크기/개수 차별화 불가
```

### 2.3 멀티 환경 요구사항

#### 환경 정의
1. **Development (Dev)**
   - 목적: 개발자 테스트 및 기능 검증
   - 특징: 최소 비용, 작은 인스턴스, Single AZ
   - Backend: LocalStack (로컬 개발용)

2. **Staging**
   - 목적: 프로덕션 배포 전 최종 검증
   - 특징: 프로덕션과 유사한 구성, Multi AZ (선택적)
   - Backend: LocalStack 또는 AWS S3 (선택 가능)

3. **Production (Prod)**
   - 목적: 실제 서비스 운영 환경
   - 특징: 고가용성, 큰 인스턴스, Multi AZ 필수
   - Backend: AWS S3 + DynamoDB (실제 운영 시)

---

## 3. 멀티 환경 구성 전략

### 3.1 디렉토리 기반 환경 분리 (채택 방식)

**선택 이유**:
- ✅ 환경별 완전한 격리 (코드, 변수, State 모두 분리)
- ✅ 환경별 독립적인 Backend 설정 가능
- ✅ 실수로 다른 환경에 배포할 위험 최소화
- ✅ 환경별 코드 차이 명확히 관리 가능
- ✅ Git 히스토리에서 환경별 변경사항 추적 용이

**구조**:
```
environments/
├── dev/
│   ├── main.tf              # 모듈 호출 (dev 설정)
│   ├── variables.tf         # 변수 정의
│   ├── terraform.tfvars     # dev 환경 변수 값
│   ├── backend.hcl          # dev backend 설정
│   ├── providers.tf         # LocalStack provider
│   └── outputs.tf           # 출력 값
├── staging/
│   ├── main.tf              # 모듈 호출 (staging 설정)
│   ├── variables.tf         # 변수 정의
│   ├── terraform.tfvars     # staging 환경 변수 값
│   ├── backend.hcl          # staging backend 설정
│   ├── providers.tf         # LocalStack or AWS provider
│   └── outputs.tf           # 출력 값
└── prod/
    ├── main.tf              # 모듈 호출 (prod 설정)
    ├── variables.tf         # 변수 정의
    ├── terraform.tfvars     # prod 환경 변수 값
    ├── backend.hcl          # prod backend 설정
    ├── providers.tf         # AWS provider (실제 운영 시)
    └── outputs.tf           # 출력 값
```

### 3.2 Workspace 기반 환경 분리 (참고용, 미채택)

**미채택 이유**:
- ❌ 같은 디렉토리에서 workspace 전환 시 실수 위험
- ❌ 환경별 코드 차이 관리 어려움
- ❌ Backend 설정 공유로 인한 제약
- ❌ 초보자에게 혼란 가능성

**참고**: Workspace는 동일한 코드로 여러 환경을 관리할 때 유용하지만,
학습 목적과 안전성을 고려하여 디렉토리 기반 방식을 채택합니다.

---

## 4. 구현 계획

### 4.1 Phase 1: 디렉토리 구조 생성

**목표**: Dev, Staging, Prod 환경 디렉토리 생성 및 기본 파일 구성

**작업 내용**:
1. `environments/dev/` 디렉토리 생성
2. `environments/staging/` 디렉토리 생성
3. `environments/prod/` 디렉토리 생성
4. `local` 디렉토리를 `dev`로 복사하여 기본 구조 활용
5. 각 환경별 `README.md` 작성 (환경 목적 및 특징 설명)

**산출물**:
- 3개 환경 디렉토리 생성 완료
- 각 디렉토리에 기본 Terraform 파일 존재

---

### 4.2 Phase 2: 환경별 변수 설정

**목표**: 각 환경에 맞는 변수 값 정의 및 차별화

**작업 내용**:

#### Dev 환경 변수 (`dev/terraform.tfvars`)
```hcl
# 프로젝트 기본 정보
project_name = "tf-lab"
env_name     = "dev"
aws_region   = "ap-northeast-2"

# VPC 설정
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a"]  # Single AZ
public_subnet_cidrs  = ["10.0.1.0/24"]
private_app_cidrs    = ["10.0.11.0/24"]
private_db_cidrs     = ["10.0.21.0/24"]

# Compute 설정
bastion_instance_type = "t2.micro"
app_instance_type     = "t2.micro"
asg_min_size          = 1
asg_max_size          = 2
asg_desired_capacity  = 1

# RDS 설정
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "devdb"
db_username          = "devadmin"
db_multi_az          = false  # Single AZ
```

#### Staging 환경 변수 (`staging/terraform.tfvars`)
```hcl
# 프로젝트 기본 정보
project_name = "tf-lab"
env_name     = "staging"
aws_region   = "ap-northeast-2"

# VPC 설정
vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]  # Multi AZ
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_app_cidrs    = ["10.1.11.0/24", "10.1.12.0/24"]
private_db_cidrs     = ["10.1.21.0/24", "10.1.22.0/24"]

# Compute 설정
bastion_instance_type = "t2.small"
app_instance_type     = "t2.small"
asg_min_size          = 2
asg_max_size          = 4
asg_desired_capacity  = 2

# RDS 설정
db_instance_class    = "db.t3.small"
db_allocated_storage = 50
db_name              = "stagingdb"
db_username          = "stagingadmin"
db_multi_az          = true  # Multi AZ
```

#### Prod 환경 변수 (`prod/terraform.tfvars`)
```hcl
# 프로젝트 기본 정보
project_name = "tf-lab"
env_name     = "prod"
aws_region   = "ap-northeast-2"

# VPC 설정
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]  # Multi AZ
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_app_cidrs    = ["10.2.11.0/24", "10.2.12.0/24"]
private_db_cidrs     = ["10.2.21.0/24", "10.2.22.0/24"]

# Compute 설정
bastion_instance_type = "t3.small"
app_instance_type     = "t3.medium"
asg_min_size          = 2
asg_max_size          = 10
asg_desired_capacity  = 4

# RDS 설정
db_instance_class    = "db.t3.medium"
db_allocated_storage = 100
db_name              = "proddb"
db_username          = "prodadmin"
db_multi_az          = true  # Multi AZ
```

**환경별 차이점 요약**:
| 항목 | Dev | Staging | Prod |
|------|-----|---------|------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Availability Zones | 1개 | 2개 | 2개 |
| Bastion 인스턴스 | t2.micro | t2.small | t3.small |
| App 인스턴스 | t2.micro | t2.small | t3.medium |
| ASG Min/Max/Desired | 1/2/1 | 2/4/2 | 2/10/4 |
| RDS 클래스 | db.t3.micro | db.t3.small | db.t3.medium |
| RDS 스토리지 | 20 GB | 50 GB | 100 GB |
| RDS Multi-AZ | No | Yes | Yes |

**산출물**:
- 3개 환경별 `terraform.tfvars` 파일 작성 완료
- 환경별 차이점 문서화

---

### 4.3 Phase 3: Backend 설정 분리

**목표**: 각 환경의 State를 완전히 격리하기 위한 Backend 설정

**작업 내용**:

#### Dev Backend (`dev/backend.hcl`)
```hcl
# LocalStack S3 Backend for Dev
bucket         = "tfstate-dev"
key            = "tf-lab/dev/terraform.tfstate"
dynamodb_table = "terraform-locks-dev"
region         = "ap-northeast-2"

# LocalStack 설정
endpoint                    = "http://localhost:4566"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
force_path_style            = true
```

#### Staging Backend (`staging/backend.hcl`)
```hcl
# LocalStack S3 Backend for Staging
bucket         = "tfstate-staging"
key            = "tf-lab/staging/terraform.tfstate"
dynamodb_table = "terraform-locks-staging"
region         = "ap-northeast-2"

# LocalStack 설정
endpoint                    = "http://localhost:4566"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
force_path_style            = true
```

#### Prod Backend (`prod/backend.hcl`)
```hcl
# 실제 AWS S3 Backend for Production (LocalStack 학습 시에는 동일 구조)
bucket         = "tfstate-prod"
key            = "tf-lab/prod/terraform.tfstate"
dynamodb_table = "terraform-locks-prod"
region         = "ap-northeast-2"

# LocalStack 설정 (실제 AWS 사용 시 이 부분 제거)
endpoint                    = "http://localhost:4566"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
force_path_style            = true
```

**Backend 격리 전략**:
- 환경별 별도의 S3 버킷 사용 (`tfstate-dev`, `tfstate-staging`, `tfstate-prod`)
- 환경별 별도의 DynamoDB 테이블 사용 (Lock 관리)
- State 파일 경로에 환경명 포함 (`tf-lab/{env}/terraform.tfstate`)

**산출물**:
- 3개 환경별 `backend.hcl` 파일 작성 완료
- Backend 격리 전략 문서화

---

### 4.4 Phase 4: 태그 및 네이밍 컨벤션

**목표**: 환경별 리소스를 명확히 구분할 수 있는 태그 및 네이밍 적용

**작업 내용**:

#### 네이밍 컨벤션
```
패턴: {project_name}-{env_name}-{resource_type}

예시:
- VPC: tf-lab-dev-vpc, tf-lab-staging-vpc, tf-lab-prod-vpc
- Bastion: tf-lab-dev-bastion, tf-lab-staging-bastion, tf-lab-prod-bastion
- ALB: tf-lab-dev-alb, tf-lab-staging-alb, tf-lab-prod-alb
- RDS: tf-lab-dev-db, tf-lab-staging-db, tf-lab-prod-db
```

#### 공통 태그 전략
모든 리소스에 자동으로 적용할 태그:
```hcl
common_tags = {
  Project     = "tf-lab"
  Environment = var.env_name  # dev, staging, prod
  ManagedBy   = "Terraform"
  CreatedAt   = "2026-01-30"
  Owner       = "DevOps-Team"
}
```

#### 변수 정의 추가 (`variables.tf`)
```hcl
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

#### 모듈 호출 시 태그 전달 (`main.tf`)
```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env_name
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-01-30"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  # ... 기존 변수들 ...

  tags = local.common_tags
}
```

**산출물**:
- 네이밍 컨벤션 문서 작성
- 공통 태그 전략 정의
- 각 환경의 `main.tf`에 태그 적용 로직 추가

---

### 4.5 Phase 5: 환경별 배포 자동화

**목표**: 환경별 배포 스크립트 작성 및 안전한 배포 절차 수립

**작업 내용**:

#### 배포 스크립트 (`scripts/deploy-env.ps1`)
```powershell
<#
.SYNOPSIS
  환경별 Terraform 배포 스크립트

.USAGE
  .\scripts\deploy-env.ps1 -Environment dev -Action plan
  .\scripts\deploy-env.ps1 -Environment staging -Action apply
  .\scripts\deploy-env.ps1 -Environment prod -Action destroy
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [ValidateSet("init", "plan", "apply", "destroy")]
    [string]$Action,

    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"
$envPath = "environments/$Environment"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

# 환경 디렉토리 존재 확인
if (-not (Test-Path $envPath)) {
    Write-Error "Environment directory not found: $envPath"
    exit 1
}

# 환경 디렉토리로 이동
Set-Location $envPath

# AWS 환경변수 설정 (LocalStack용)
. ..\..\scripts\set-localstack-env.ps1

# Terraform 명령 실행
switch ($Action) {
    "init" {
        Write-Host "Initializing Terraform..." -ForegroundColor Green
        terraform init -backend-config=backend.hcl
    }
    "plan" {
        Write-Host "Planning Terraform..." -ForegroundColor Green
        terraform plan -var-file=terraform.tfvars
    }
    "apply" {
        Write-Host "Applying Terraform..." -ForegroundColor Green
        if ($AutoApprove) {
            terraform apply -var-file=terraform.tfvars -auto-approve
        } else {
            terraform apply -var-file=terraform.tfvars
        }
    }
    "destroy" {
        Write-Host "Destroying Terraform..." -ForegroundColor Red
        Write-Warning "This will destroy all resources in $Environment environment!"
        if ($AutoApprove) {
            terraform destroy -var-file=terraform.tfvars -auto-approve
        } else {
            terraform destroy -var-file=terraform.tfvars
        }
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Completed: $Action for $Environment" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
```

#### Backend 초기화 스크립트 (`scripts/init-backends.ps1`)
```powershell
<#
.SYNOPSIS
  모든 환경의 Backend 인프라를 LocalStack에 생성

.USAGE
  .\scripts\init-backends.ps1
#>

$ErrorActionPreference = "Stop"

# AWS 환경변수 설정
. .\scripts\set-localstack-env.ps1

Write-Host "Creating backend infrastructure for all environments..." -ForegroundColor Cyan

$environments = @("dev", "staging", "prod")

foreach ($env in $environments) {
    Write-Host "`n==== Environment: $env ====" -ForegroundColor Yellow

    # S3 버킷 생성
    $bucket = "tfstate-$env"
    Write-Host "Creating S3 bucket: $bucket" -ForegroundColor Green
    aws s3 mb "s3://$bucket" --endpoint-url=http://localhost:4566 2>$null

    # 버킷 버저닝 활성화
    Write-Host "Enabling versioning for: $bucket" -ForegroundColor Green
    aws s3api put-bucket-versioning `
        --bucket $bucket `
        --versioning-configuration Status=Enabled `
        --endpoint-url=http://localhost:4566

    # DynamoDB 테이블 생성
    $table = "terraform-locks-$env"
    Write-Host "Creating DynamoDB table: $table" -ForegroundColor Green
    aws dynamodb create-table `
        --table-name $table `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --endpoint-url=http://localhost:4566 2>$null
}

Write-Host "`n==== All backend resources created successfully! ====" -ForegroundColor Green
```

#### 검증 스크립트 (`scripts/validate-env.ps1`)
```powershell
<#
.SYNOPSIS
  환경별 배포 결과 검증

.USAGE
  .\scripts\validate-env.ps1 -Environment dev
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment
)

$envPath = "environments/$Environment"

Write-Host "Validating $Environment environment..." -ForegroundColor Cyan

# Terraform 출력 값 확인
Set-Location $envPath
$outputs = terraform output -json | ConvertFrom-Json

Write-Host "`nVPC ID: $($outputs.vpc_id.value)" -ForegroundColor Green
Write-Host "Bastion Public IP: $($outputs.bastion_public_ip.value)" -ForegroundColor Green

# 리소스 개수 확인
$stateList = terraform state list
Write-Host "`nTotal resources: $($stateList.Count)" -ForegroundColor Yellow

Write-Host "`nValidation complete for $Environment" -ForegroundColor Green
```

**산출물**:
- `scripts/deploy-env.ps1` (환경별 배포 스크립트)
- `scripts/init-backends.ps1` (Backend 초기화 스크립트)
- `scripts/validate-env.ps1` (검증 스크립트)
- 배포 절차 문서화

---

### 4.6 Phase 6: 테스트 및 검증

**목표**: Dev 환경에 배포하여 멀티 환경 구성 동작 확인

**검증 절차**:

1. **Backend 초기화**
   ```powershell
   .\scripts\init-backends.ps1
   ```

2. **Dev 환경 배포**
   ```powershell
   .\scripts\deploy-env.ps1 -Environment dev -Action init
   .\scripts\deploy-env.ps1 -Environment dev -Action plan
   .\scripts\deploy-env.ps1 -Environment dev -Action apply
   ```

3. **검증**
   ```powershell
   .\scripts\validate-env.ps1 -Environment dev
   ```

4. **State 격리 확인**
   ```powershell
   # Dev State 확인
   aws s3 ls s3://tfstate-dev/tf-lab/dev/ --endpoint-url=http://localhost:4566

   # Staging State 확인 (비어있어야 함)
   aws s3 ls s3://tfstate-staging/tf-lab/staging/ --endpoint-url=http://localhost:4566
   ```

5. **리소스 네이밍 확인**
   - VPC 이름: `tf-lab-dev-vpc`
   - 태그: `Environment = dev`

**성공 기준**:
- ✅ Dev 환경 리소스가 정상 배포됨
- ✅ State 파일이 `tfstate-dev` 버킷에 저장됨
- ✅ 리소스 네이밍에 `dev` 포함
- ✅ 모든 리소스에 `Environment: dev` 태그 적용
- ✅ Staging/Prod State는 비어있음 (격리 확인)

**산출물**:
- 검증 결과 문서
- 스크린샷 (리소스 목록, State 파일, 태그)

---

## 5. 리스크 관리 (Risk Management)

### 5.1 환경 혼동 리스크

**리스크**: 개발자가 실수로 다른 환경에 배포할 가능성

**완화 전략**:
- ✅ 디렉토리 기반 분리로 작업 디렉토리 명확화
- ✅ 배포 스크립트에 환경명 필수 파라미터로 지정
- ✅ Prod 배포 시 명시적인 확인 절차 추가
- ✅ 환경별 다른 색상으로 프롬프트 표시 (옵션)

**대응 방안**:
```powershell
# Prod 배포 시 추가 확인
if ($Environment -eq "prod" -and -not $AutoApprove) {
    $confirm = Read-Host "You are deploying to PRODUCTION. Type 'CONFIRM' to proceed"
    if ($confirm -ne "CONFIRM") {
        Write-Error "Production deployment cancelled."
        exit 1
    }
}
```

### 5.2 변수 불일치 리스크

**리스크**: 환경별 변수 파일이 sync가 맞지 않을 수 있음

**완화 전략**:
- ✅ 공통 변수는 `variables.tf`에 정의
- ✅ 환경별 차이만 `terraform.tfvars`에 기록
- ✅ 변수 검증 로직 추가 (예: VPC CIDR 중복 방지)
- ✅ 문서화된 변수 차이 테이블 유지

**대응 방안**:
```hcl
# variables.tf에 검증 로직 추가
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}
```

### 5.3 Backend State 충돌 리스크

**리스크**: 동일 환경에 여러 사람이 동시 작업 시 Lock 충돌

**완화 전략**:
- ✅ DynamoDB Lock 테이블 사용
- ✅ Terraform 작업 전 팀 커뮤니케이션
- ✅ Lock 타임아웃 설정

**대응 방안**:
```bash
# Lock 강제 해제 (비상시만 사용)
terraform force-unlock <LOCK_ID>
```

### 5.4 LocalStack 제약사항

**리스크**: LocalStack Community 버전에서 일부 리소스 미지원

**완화 전략**:
- ✅ Step 3에서 확인된 제약사항 문서화됨 (ALB, RDS, ASG 일부)
- ✅ 학습 목적으로 제약사항 수용
- ✅ 실제 AWS 배포 시에는 모든 기능 작동 예상

**대응 방안**:
- 학습 단계에서는 LocalStack 제약 수용
- 향후 실제 AWS 배포 시 전체 테스트 필요

---

## 6. 일정 (Timeline)

| Phase | 작업 내용 | 예상 시간 | 산출물 |
|-------|-----------|-----------|--------|
| Phase 1 | 디렉토리 구조 생성 | 10분 | 3개 환경 디렉토리 |
| Phase 2 | 환경별 변수 설정 | 20분 | terraform.tfvars × 3 |
| Phase 3 | Backend 설정 분리 | 15분 | backend.hcl × 3 |
| Phase 4 | 태그/네이밍 컨벤션 | 15분 | 태그 전략 문서, 코드 수정 |
| Phase 5 | 배포 자동화 스크립트 | 30분 | 3개 PowerShell 스크립트 |
| Phase 6 | 테스트 및 검증 | 20분 | 검증 보고서 |
| **총 예상 시간** | | **110분 (1시간 50분)** | |

---

## 7. 환경별 비교표

### 7.1 인프라 구성 차이

| 구성 요소 | Dev | Staging | Prod |
|-----------|-----|---------|------|
| **VPC** |
| CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Availability Zones | 1 (2a) | 2 (2a, 2c) | 2 (2a, 2c) |
| Public Subnets | 1 | 2 | 2 |
| Private App Subnets | 1 | 2 | 2 |
| Private DB Subnets | 1 | 2 | 2 |
| **Compute** |
| Bastion 타입 | t2.micro | t2.small | t3.small |
| App 인스턴스 타입 | t2.micro | t2.small | t3.medium |
| ASG Min | 1 | 2 | 2 |
| ASG Max | 2 | 4 | 10 |
| ASG Desired | 1 | 2 | 4 |
| **RDS** |
| 인스턴스 클래스 | db.t3.micro | db.t3.small | db.t3.medium |
| 스토리지 | 20 GB | 50 GB | 100 GB |
| Multi-AZ | ❌ No | ✅ Yes | ✅ Yes |
| 백업 보관 | 1일 | 7일 | 14일 |
| **Backend** |
| S3 Bucket | tfstate-dev | tfstate-staging | tfstate-prod |
| DynamoDB Table | terraform-locks-dev | terraform-locks-staging | terraform-locks-prod |
| Provider | LocalStack | LocalStack | LocalStack (학습), AWS (운영) |

### 7.2 비용 추정 (실제 AWS 사용 시)

| 환경 | 월 예상 비용 (USD) | 주요 비용 요인 |
|------|---------------------|----------------|
| Dev | ~$50 | Single AZ, 작은 인스턴스, RDS Single-AZ |
| Staging | ~$150 | Multi-AZ, 중간 인스턴스, RDS Multi-AZ |
| Prod | ~$400 | Multi-AZ, 큰 인스턴스, HA 구성, 백업 |

*참고*: LocalStack 사용 시에는 비용 발생하지 않음 (로컬 환경)

---

## 8. 다음 단계 (Next Steps)

### 8.1 이번 단계 완료 후
1. ✅ Dev, Staging, Prod 3개 환경 구성 완료
2. ✅ 환경별 독립적인 State 관리
3. ✅ 환경별 배포 자동화 스크립트
4. ✅ 네이밍 및 태그 컨벤션 적용

### 8.2 향후 확장 가능 항목
- **Step 5**: Terraform 모듈 고도화 (Module Registry, Versioning)
- **Step 6**: CI/CD 파이프라인 구축 (GitHub Actions, GitLab CI)
- **Step 7**: Monitoring & Logging (CloudWatch, Prometheus, Grafana)
- **Step 8**: Disaster Recovery 전략 (Backup, Snapshot, Cross-Region)
- **Step 9**: Security 강화 (AWS WAF, GuardDuty, Security Hub)
- **Step 10**: Cost Optimization (RI, Spot Instances, Auto-Scaling)

---

## 9. 참고 자료 (References)

### 9.1 Terraform 공식 문서
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Managing Multiple Environments](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration)

### 9.2 LocalStack 문서
- [LocalStack Multi-Account Setup](https://docs.localstack.cloud/user-guide/aws/multi-account-setups/)
- [LocalStack S3 Backend](https://docs.localstack.cloud/user-guide/integrations/terraform/)

### 9.3 Best Practices
- [Terraform Best Practices by Gruntwork](https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa)
- [Environment Separation Strategies](https://www.terraform-best-practices.com/code-structure)
- [AWS Tagging Best Practices](https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html)

### 9.4 내부 문서
- [Step 1 - Infrastructure Expansion Plan](20260130-infrastructure-expansion.plan.md)
- [Step 2 - Infrastructure Modulization Plan](20260130-infrastructure-modulization.plan.md)
- [Step 3 - LocalStack Deployment Plan](20260130-localstack-deployment.plan.md)

---

## 10. 변경 이력 (Change Log)

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2026-01-30 | 1.0 | 초안 작성 - Multi-Environment Setup 계획 수립 | Claude Code |

---

**다음 문서**: [Design - Multi-Environment Setup](../../02-design/features/20260130-multi-environment-setup.design.md)
