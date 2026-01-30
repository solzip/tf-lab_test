# Plan: LocalStack Deployment & Validation

**작성일**: 2026-01-30
**작성자**: Claude Code
**Feature ID**: localstack-deployment
**PDCA Phase**: Plan
**이전 단계**: [Step 2 - Infrastructure Modulization](20260130-infrastructure-modulization.plan.md)

---

## 1. 목표 (Objectives)

### 1.1 주요 목표
모듈화된 Terraform 인프라를 LocalStack 환경에 실제 배포하고 검증하여 동작을 확인한다.

### 1.2 학습 목표
- LocalStack을 활용한 로컬 AWS 환경 구축 방법 학습
- Terraform Backend (S3 + DynamoDB) 구성 및 State 관리
- 실제 인프라 배포 및 검증 절차 체득
- 배포 과정에서 발생하는 문제 해결 능력 배양
- End-to-End 인프라 테스트 방법론 습득

### 1.3 성공 기준
- [ ] LocalStack이 정상적으로 실행되고 AWS 서비스 에뮬레이션
- [ ] S3 Backend와 DynamoDB Lock 테이블이 생성되고 작동
- [ ] `terraform init`가 Backend와 함께 성공
- [ ] `terraform plan`이 43개 리소스를 정확히 계획
- [ ] `terraform apply`가 에러 없이 모든 리소스 생성
- [ ] ALB DNS 주소로 웹 페이지 접속 가능
- [ ] EC2 인스턴스가 Auto Scaling Group에 등록
- [ ] RDS 인스턴스가 생성되고 연결 가능
- [ ] Health Check 엔드포인트 (`/health`) 응답 확인
- [ ] 배포 과정과 검증 절차가 문서화됨

---

## 2. 현황 분석 (Current State)

### 2.1 완료된 사항
✅ **Step 1**: 3-Tier 인프라 설계 및 구현 (67 resources)
✅ **Step 2**: 모듈화 완료 (5 modules, 43 resources)
✅ **PDCA 문서**: Plan, Design, Implementation, Report 완성
✅ **코드 검증**: terraform fmt, validate, plan 통과
✅ **Git 커밋**: 모든 변경사항 버전 관리

### 2.2 현재 상태
```
modules/
├── vpc/                 ✅ 구현 완료
├── security-groups/     ✅ 구현 완료
├── compute/             ✅ 구현 완료
├── alb/                 ✅ 구현 완료
└── rds/                 ✅ 구현 완료

environments/local/
├── main.tf              ✅ 모듈 호출 설정
├── variables.tf         ✅ 변수 정의
├── terraform.tfvars     ✅ 변수 값 설정
├── backend.tf           ✅ S3 Backend 정의
├── backend.hcl          ✅ Backend 설정 값
├── providers.tf         ✅ LocalStack Provider
└── user-data.sh         ✅ Apache 설치 스크립트

배포 상태: ❌ 미배포 (LocalStack에 적용 안 됨)
```

### 2.3 LocalStack 요구사항
- Docker 실행 환경
- LocalStack 컨테이너 실행
- 필요 서비스: EC2, VPC, ELB, RDS, S3, DynamoDB, IAM, STS
- 포트: 4566 (모든 서비스 통합 엔드포인트)

---

## 3. 배포 전략 (Deployment Strategy)

### 3.1 배포 단계 (5 Phases)

#### Phase 1: LocalStack 준비
**목표**: LocalStack 환경 실행 및 서비스 확인

```bash
# 1. LocalStack 실행 확인
docker ps | grep localstack

# 2. 서비스 헬스 체크
curl http://localhost:4566/_localstack/health

# 3. AWS CLI 설정 확인 (awslocal)
awslocal --version
```

**산출물**:
- LocalStack 컨테이너 실행 중
- 필요 서비스(EC2, VPC, ELB, RDS, S3, DynamoDB) Ready 상태

---

#### Phase 2: Backend 인프라 구성
**목표**: Terraform State 저장을 위한 S3 + DynamoDB 설정

```bash
# 1. S3 버킷 생성
awslocal s3 mb s3://tfstate-local

# 2. 버킷 확인
awslocal s3 ls

# 3. DynamoDB 테이블 생성 (State Lock용)
awslocal dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# 4. 테이블 확인
awslocal dynamodb list-tables
```

**검증**:
- `s3://tfstate-local` 버킷 존재
- `terraform-locks` DynamoDB 테이블 존재

---

#### Phase 3: Terraform 초기화 및 Plan
**목표**: Backend와 함께 Terraform 초기화, Plan 실행

```bash
# 작업 디렉토리
cd environments/local

# 1. 환경 변수 설정 (PowerShell)
. ../../scripts/set-localstack-env.ps1

# 2. Backend 설정과 함께 초기화
terraform init -backend-config=backend.hcl

# 3. Plan 실행
terraform plan -var-file=terraform.tfvars -out=tfplan

# 4. Plan 파일 확인
terraform show tfplan
```

**예상 결과**:
- 모듈 로드: 5개 (vpc, security_groups, compute, alb, rds)
- 생성 계획: 43 resources
- Backend 연결: S3 + DynamoDB Lock

**주요 확인사항**:
- `.terraform/` 디렉토리 생성
- `.terraform.lock.hcl` Provider Lock 파일 생성
- Backend 초기화 메시지 출력

---

#### Phase 4: Infrastructure Deployment
**목표**: 실제 리소스 배포 (`terraform apply`)

```bash
# 1. Apply 실행 (승인 필요)
terraform apply tfplan

# 또는 자동 승인
terraform apply -var-file=terraform.tfvars -auto-approve

# 2. 진행 상황 모니터링
# - VPC 생성
# - Subnets 생성 (6개)
# - Internet Gateway, NAT Gateway
# - Security Groups (4개)
# - ALB, Target Group
# - Launch Template, ASG
# - Bastion Instance
# - RDS Instance
```

**예상 소요 시간**: 3-5분 (LocalStack)

**체크포인트**:
- ✅ VPC 생성: 10.10.0.0/16
- ✅ Subnets: Public (2), Private App (2), Private DB (2)
- ✅ NAT Gateway: 1개 (Public Subnet)
- ✅ Security Groups: ALB, App, Bastion, DB
- ✅ ALB: Internet-facing
- ✅ ASG: Min 2, Desired 2, Max 4
- ✅ Bastion: Public IP 할당
- ✅ RDS: MySQL 8.0.35

---

#### Phase 5: 배포 검증 (Validation)
**목표**: 배포된 인프라의 정상 동작 확인

##### 5.1 리소스 생성 확인
```bash
# 1. Terraform 상태 확인
terraform state list

# 2. Outputs 확인
terraform output

# 예상 Outputs:
# - vpc_id
# - alb_dns_name
# - bastion_public_ip
# - rds_endpoint (sensitive)
# - asg_name
```

##### 5.2 AWS CLI로 리소스 조회
```bash
# VPC 확인
awslocal ec2 describe-vpcs

# Subnets 확인
awslocal ec2 describe-subnets

# Security Groups 확인
awslocal ec2 describe-security-groups

# EC2 Instances 확인
awslocal ec2 describe-instances

# ALB 확인
awslocal elbv2 describe-load-balancers

# Target Group 확인
awslocal elbv2 describe-target-groups
awslocal elbv2 describe-target-health --target-group-arn <arn>

# RDS 확인
awslocal rds describe-db-instances
```

##### 5.3 웹 애플리케이션 접속 테스트
```bash
# 1. ALB DNS 확인
ALB_DNS=$(terraform output -raw alb_dns_name)

# 2. Health Check 엔드포인트 테스트
curl http://$ALB_DNS/health
# 예상 응답: "OK"

# 3. 메인 페이지 접속
curl http://$ALB_DNS/

# 4. 브라우저 접속
# http://<alb-dns-name>
# 예상: "Hello from Modular Terraform!" 페이지 표시
```

##### 5.4 Auto Scaling 확인
```bash
# ASG 인스턴스 수 확인
awslocal autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names tf-lab-local-asg

# Target Group에 등록된 인스턴스 확인
awslocal elbv2 describe-target-health \
  --target-group-arn <arn>

# 예상: 2개 인스턴스 healthy 상태
```

##### 5.5 RDS 연결 테스트
```bash
# RDS 엔드포인트 확인
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

# MySQL 연결 시도 (LocalStack 제약으로 제한적)
# 실제 AWS에서는:
# mysql -h $RDS_ENDPOINT -u admin -p
```

---

## 4. 예상 문제 및 대응 (Risk Management)

### 4.1 LocalStack 제약사항

| 문제 | 설명 | 대응 방안 |
|------|------|----------|
| **RDS 제한** | LocalStack Community는 RDS 완전 지원 안 함 | RDS는 생성만 확인, 실제 연결은 Pro 버전 필요 |
| **ALB 제한** | ALB가 실제 트래픽 라우팅 안 할 수 있음 | 직접 EC2 인스턴스 IP로 접속 테스트 |
| **NAT Gateway** | NAT 기능이 제한적 | 네트워크 연결성은 제한적으로 동작 |
| **Auto Scaling** | Scaling 이벤트가 실제 발생하지 않음 | ASG 리소스 생성 자체에 집중 |
| **메타데이터** | EC2 메타데이터 API 제한 | user-data.sh의 fallback 로직 활용 |

### 4.2 예상 에러 시나리오

#### 시나리오 1: Backend 초기화 실패
**증상**:
```
Error: Failed to get existing workspaces: Unable to list objects in S3 bucket
```

**원인**: S3 버킷 미생성 또는 LocalStack 미실행

**해결**:
```bash
# LocalStack 실행 확인
docker ps | grep localstack

# S3 버킷 생성
awslocal s3 mb s3://tfstate-local
```

---

#### 시나리오 2: Provider 인증 실패
**증상**:
```
Error: No valid credential sources found
```

**원인**: AWS 환경 변수 미설정

**해결**:
```powershell
# PowerShell 환경 변수 설정
. .\scripts\set-localstack-env.ps1

# 확인
echo $env:AWS_ACCESS_KEY_ID
echo $env:AWS_EC2_METADATA_DISABLED
```

---

#### 시나리오 3: AMI ID 오류
**증상**:
```
Error: Invalid AMI ID format
```

**원인**: LocalStack은 실제 AMI를 검증하지 않음

**해결**:
- `terraform.tfvars`의 `ami_id`는 임의 값 사용 가능
- LocalStack에서는 형식만 맞으면 됨: `ami-xxxxxxxx`

---

#### 시나리오 4: RDS 생성 실패
**증상**:
```
Error: creating RDS DB Instance: ...
```

**원인**: LocalStack Community 버전의 RDS 제한

**해결**:
- RDS 모듈을 일시적으로 주석 처리
- 또는 LocalStack Pro 사용
- 또는 에러 무시하고 다른 리소스 확인

---

#### 시나리오 5: ALB DNS 접속 불가
**증상**: ALB DNS로 curl 시 응답 없음

**원인**: LocalStack ALB의 라우팅 제한

**해결**:
```bash
# EC2 인스턴스 직접 접속
INSTANCE_IP=$(awslocal ec2 describe-instances \
  --filters "Name=tag:Name,Values=tf-lab-local-asg-instance" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

curl http://$INSTANCE_IP/
```

---

## 5. 산출물 (Deliverables)

### 5.1 배포 결과
- [ ] LocalStack 환경에 43개 리소스 배포 완료
- [ ] Terraform State가 S3에 저장되고 DynamoDB Lock 작동
- [ ] 웹 애플리케이션 접속 가능 (ALB 또는 직접 접속)
- [ ] 주요 리소스 동작 확인 (VPC, Subnets, SG, ALB, ASG, Bastion)

### 5.2 문서
- [ ] **배포 가이드** (`docs/guides/localstack-deployment-guide.md`)
  - LocalStack 설정 방법
  - 단계별 배포 절차
  - 검증 체크리스트

- [ ] **트러블슈팅 가이드** (`docs/guides/troubleshooting.md`)
  - 자주 발생하는 에러 및 해결법
  - LocalStack 제약사항 정리
  - 디버깅 팁

- [ ] **검증 보고서** (`docs/03-validation/20260130-deployment-validation.md`)
  - 배포 성공/실패 리소스 목록
  - 접속 테스트 결과
  - 스크린샷 (웹 페이지, CLI 출력)

### 5.3 스크립트
- [ ] **배포 스크립트** (`scripts/deploy-localstack.sh` 또는 `.ps1`)
  - 원클릭 배포 자동화
  - Backend 설정, init, plan, apply 통합

- [ ] **검증 스크립트** (`scripts/validate-deployment.sh` 또는 `.ps1`)
  - 자동 리소스 확인
  - Health Check
  - 보고서 생성

---

## 6. 일정 및 마일스톤 (Timeline)

### Phase별 예상 소요 시간
```
Phase 1: LocalStack 준비          - 10분
Phase 2: Backend 구성              - 10분
Phase 3: Terraform Init & Plan     - 10분
Phase 4: Infrastructure Deployment - 15분
Phase 5: 검증 및 테스트            - 15분
─────────────────────────────────────────
총 예상 시간:                      - 60분
```

### 마일스톤
- **M1**: LocalStack 환경 준비 완료 (Phase 1-2)
- **M2**: Terraform Plan 성공 (Phase 3)
- **M3**: 인프라 배포 완료 (Phase 4)
- **M4**: 검증 및 문서화 완료 (Phase 5)

---

## 7. 성공 지표 (Success Metrics)

### 7.1 배포 성공률
```
목표: 43개 리소스 중 95% 이상 성공 (41개 이상)

LocalStack 제약으로 인해 일부 리소스는 부분 성공 가능:
- RDS: 생성은 되지만 연결 제한
- ALB: 생성은 되지만 라우팅 제한
- NAT Gateway: 생성되지만 기능 제한
```

### 7.2 검증 항목
- [ ] VPC 및 Subnets: 100% 동작
- [ ] Security Groups: 100% 생성
- [ ] EC2 Instances (ASG): 100% 생성
- [ ] Bastion Host: 100% 생성, Public IP 할당
- [ ] ALB: 생성 성공 (라우팅은 제한적)
- [ ] RDS: 생성 성공 (연결은 제한적)
- [ ] 웹 페이지 접속: 가능 (ALB 또는 직접)
- [ ] Health Check: 응답 성공

### 7.3 학습 목표 달성
- [ ] LocalStack 환경 설정 및 사용법 이해
- [ ] Terraform Backend (S3 + DynamoDB) 구성 경험
- [ ] 실제 배포 과정 체험 및 문제 해결
- [ ] 인프라 검증 방법론 습득
- [ ] LocalStack 제약사항 및 실제 AWS 차이점 이해

---

## 8. 리스크 및 대응 (Risks & Mitigation)

| 리스크 | 영향 | 확률 | 대응 방안 |
|--------|------|------|----------|
| LocalStack 미실행 | High | Low | 사전 확인 체크리스트 |
| Backend 설정 실패 | High | Medium | 단계별 검증 포인트 |
| RDS 생성 실패 | Low | High | LocalStack Pro 권장 또는 스킵 |
| ALB 라우팅 불가 | Medium | High | 직접 EC2 접속 대안 |
| 환경 변수 미설정 | High | Medium | 스크립트 자동화 |
| Docker 리소스 부족 | Medium | Low | Docker 메모리 증설 |

---

## 9. 다음 단계 (Next Steps)

배포 성공 후 고려할 후속 작업:

### 9.1 즉시 (Immediate)
1. **배포 스크립트 자동화**: 반복 배포를 위한 스크립트 작성
2. **Destroy 테스트**: `terraform destroy`로 안전한 리소스 삭제 확인
3. **State 검증**: S3에 저장된 state 파일 구조 확인

### 9.2 단기 (Short-term)
4. **Multi-Environment**: dev, prod 환경 추가
5. **Testing 전략**: Terratest로 자동 테스트 구현
6. **CI/CD 파이프라인**: GitHub Actions 통합

### 9.3 중장기 (Long-term)
7. **실제 AWS 배포**: LocalStack에서 실제 AWS로 전환
8. **모니터링**: CloudWatch 통합
9. **Security**: AWS Config, Security Hub 적용

---

## 10. 참고 자료 (References)

### 10.1 공식 문서
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/backend)

### 10.2 내부 문서
- [Step 1 Implementation](../../03-implementation/20260130-infrastructure-expansion.implementation.md)
- [Step 2 Implementation](../../03-implementation/20260130-infrastructure-modulization.implementation.md)
- [Module Design Document](../../02-design/features/20260130-infrastructure-modulization.design.md)

### 10.3 유용한 명령어
```bash
# LocalStack 상태 확인
docker ps
curl http://localhost:4566/_localstack/health

# AWS CLI (LocalStack)
awslocal <service> <command>

# Terraform
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -auto-approve
terraform destroy -auto-approve

# 디버깅
terraform console
terraform state list
terraform show
```

---

## 11. 체크리스트 (Checklist)

### 사전 준비
- [ ] Docker 실행 중
- [ ] LocalStack 컨테이너 실행 중
- [ ] awslocal CLI 설치됨
- [ ] PowerShell 환경 변수 스크립트 준비됨

### Phase 1: LocalStack
- [ ] LocalStack Health Check 통과
- [ ] 필요 서비스 Ready 확인

### Phase 2: Backend
- [ ] S3 버킷 `tfstate-local` 생성
- [ ] DynamoDB 테이블 `terraform-locks` 생성

### Phase 3: Init & Plan
- [ ] 환경 변수 설정 완료
- [ ] `terraform init` 성공
- [ ] `terraform plan` 성공 (43 resources)

### Phase 4: Deployment
- [ ] `terraform apply` 성공
- [ ] 모든 모듈 리소스 생성 확인

### Phase 5: Validation
- [ ] `terraform output` 확인
- [ ] VPC 및 Subnets 생성 확인
- [ ] Security Groups 확인
- [ ] EC2 Instances 확인
- [ ] ALB 생성 확인
- [ ] 웹 페이지 접속 성공
- [ ] Health Check 응답 확인

### 문서화
- [ ] 배포 가이드 작성
- [ ] 트러블슈팅 가이드 작성
- [ ] 검증 보고서 작성
- [ ] 스크린샷 첨부

---

**작성 완료일**: 2026-01-30
**다음 단계**: Design Phase - 상세 배포 절차 설계
**예상 소요**: 1-2시간 (실습 포함)
