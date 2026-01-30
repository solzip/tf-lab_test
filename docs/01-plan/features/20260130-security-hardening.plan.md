# Plan: Security Hardening (보안 강화)

**작성일**: 2026-01-30
**작성자**: Claude Code
**Feature ID**: security-hardening
**PDCA Phase**: Plan
**이전 단계**: [Step 4 - Multi-Environment Setup](20260130-multi-environment-setup.plan.md)

---

## 1. 목표 (Objectives)

### 1.1 주요 목표
운영 환경의 보안을 강화하여 데이터 유출, 무단 접근, 악의적 공격으로부터 인프라를 보호한다.

### 1.2 학습 목표
- AWS Secrets Manager를 활용한 민감 정보 관리
- IAM Role 최소 권한 원칙 (Principle of Least Privilege) 적용
- Security Group 최적화 및 네트워크 보안 강화
- 데이터 암호화 전략 (전송 중/저장 시)
- VPC Flow Logs를 통한 네트워크 트래픽 모니터링
- 보안 취약점 스캔 및 감사 로그 설정
- AWS Security Best Practices 이해

### 1.3 성공 기준
- [ ] AWS Secrets Manager에 DB 비밀번호 저장 및 Terraform 연동
- [ ] IAM Role 생성 및 EC2 인스턴스에 연결
- [ ] Security Group 규칙 최소화 (필요한 포트만 개방)
- [ ] RDS 암호화 활성화 (저장 시 암호화)
- [ ] S3 버킷 암호화 및 버저닝 활성화
- [ ] VPC Flow Logs 설정 및 CloudWatch Logs 전송
- [ ] ALB HTTPS 리스너 설정 (ACM 인증서)
- [ ] Systems Manager Session Manager를 통한 Bastion 대체 (선택적)
- [ ] 모든 보안 설정이 Terraform 코드로 관리됨
- [ ] Dev, Staging, Prod 환경 모두 적용

---

## 2. 현황 분석 (Current State)

### 2.1 완료된 사항
✅ **Step 1-4**: 인프라 확장, 모듈화, LocalStack 배포, 멀티 환경 구성
✅ **현재 인프라**: Dev, Staging, Prod 3개 환경 구성 완료
✅ **기본 보안**: Security Groups 설정, Private Subnet 분리

### 2.2 현재 보안 상태

#### 강점
- ✅ VPC 네트워크 분리 (Public, Private App, Private DB)
- ✅ Security Groups 기본 설정 (Bastion, App, ALB, RDS)
- ✅ RDS가 Private Subnet에 배치
- ✅ NAT Gateway를 통한 아웃바운드 트래픽 제어

#### 취약점
- ❌ **DB 비밀번호가 terraform.tfvars에 평문 저장**
- ❌ **IAM Role 미사용** (EC2 인스턴스가 하드코딩된 자격증명 사용 가능성)
- ❌ **Security Group 규칙이 너무 광범위** (0.0.0.0/0 SSH 허용)
- ❌ **RDS 암호화 미활성화**
- ❌ **S3 Backend 버킷 암호화 미설정**
- ❌ **HTTPS 미설정** (ALB가 HTTP만 사용)
- ❌ **VPC Flow Logs 미설정** (네트워크 트래픽 추적 불가)
- ❌ **CloudTrail 감사 로그 미설정**

### 2.3 보안 위험 평가

| 위험 | 심각도 | 현재 상태 | 우선순위 |
|------|--------|-----------|----------|
| DB 비밀번호 평문 노출 | 🔴 Critical | 취약 | 1 |
| 과도한 SSH 접근 허용 (0.0.0.0/0) | 🟠 High | 취약 | 2 |
| IAM Role 미사용 | 🟠 High | 취약 | 3 |
| 데이터 암호화 미적용 | 🟠 High | 취약 | 4 |
| HTTPS 미설정 | 🟡 Medium | 취약 | 5 |
| VPC Flow Logs 없음 | 🟡 Medium | 취약 | 6 |
| CloudTrail 감사 없음 | 🟡 Medium | 취약 | 7 |

---

## 3. 보안 강화 전략

### 3.1 Phase별 구현 계획 (7 Phases)

#### Phase 1: AWS Secrets Manager 통합
**목표**: DB 비밀번호를 Secrets Manager로 이전

**작업 내용**:
1. Secrets Manager 시크릿 생성 (환경별)
2. Terraform에서 `aws_secretsmanager_secret` 리소스 정의
3. RDS 모듈에서 Secrets Manager 참조
4. `terraform.tfvars`에서 평문 비밀번호 제거

**산출물**:
- `modules/secrets/main.tf` (새 모듈)
- RDS 모듈 업데이트
- 환경별 Secrets Manager 시크릿

**소요 시간**: 30분

---

#### Phase 2: IAM Role 및 Instance Profile 설정
**목표**: EC2 인스턴스가 AWS 서비스에 안전하게 접근

**작업 내용**:
1. IAM Role 생성 (`ec2-app-role`, `ec2-bastion-role`)
2. 필요한 최소 권한 정책 연결:
   - S3 읽기 (애플리케이션 에셋)
   - Secrets Manager 읽기 (DB 접근)
   - CloudWatch Logs 쓰기 (로그 전송)
3. Instance Profile 생성
4. EC2 Launch Template에 Instance Profile 연결

**산출물**:
- `modules/iam/main.tf` (새 모듈)
- Compute 모듈 업데이트 (Instance Profile 연결)

**소요 시간**: 40분

---

#### Phase 3: Security Group 최적화
**목표**: 최소 권한 원칙에 따라 Security Group 규칙 최적화

**작업 내용**:
1. **Bastion SG**:
   - SSH (22): 특정 IP 대역만 허용 (관리자 IP)
   - 0.0.0.0/0 제거

2. **App SG**:
   - HTTP (80): ALB SG에서만 허용
   - SSH (22): Bastion SG에서만 허용

3. **ALB SG**:
   - HTTP (80): 0.0.0.0/0 허용 (웹 서비스)
   - HTTPS (443): 0.0.0.0/0 허용 (웹 서비스)

4. **RDS SG**:
   - MySQL (3306): App SG에서만 허용

**변수 추가**:
```hcl
variable "admin_ip_ranges" {
  description = "Admin IP ranges for SSH access"
  type        = list(string)
  default     = ["1.2.3.4/32"]  # 관리자 IP로 변경
}
```

**산출물**:
- Security Groups 모듈 업데이트
- 환경별 `admin_ip_ranges` 설정

**소요 시간**: 20분

---

#### Phase 4: 데이터 암호화
**목표**: 저장 시 암호화 (Encryption at Rest) 활성화

**4.1 RDS 암호화**:
```hcl
resource "aws_db_instance" "main" {
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn
}
```

**4.2 S3 Backend 암호화**:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "backend" {
  bucket = aws_s3_bucket.backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}
```

**4.3 KMS Key 생성**:
- RDS 암호화용 KMS Key
- S3 암호화용 KMS Key
- 환경별 독립적인 Key

**산출물**:
- `modules/kms/main.tf` (새 모듈)
- RDS 모듈 업데이트 (암호화 활성화)
- S3 Backend 암호화 스크립트

**소요 시간**: 40분

---

#### Phase 5: HTTPS 설정 (ALB)
**목표**: ALB에 HTTPS 리스너 추가 및 HTTP → HTTPS 리다이렉트

**작업 내용**:
1. ACM (AWS Certificate Manager) 인증서 요청
   - 도메인이 없으면 자체 서명 인증서 또는 생략

2. ALB에 HTTPS 리스너 추가:
```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

3. HTTP 리스너를 HTTPS로 리다이렉트:
```hcl
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

**산출물**:
- ACM 인증서 (선택적, 도메인 필요)
- ALB 모듈 업데이트 (HTTPS 리스너)

**소요 시간**: 30분 (도메인 없으면 생략 가능)

---

#### Phase 6: VPC Flow Logs
**목표**: VPC 네트워크 트래픽 로깅 및 모니터링

**작업 내용**:
1. CloudWatch Logs Group 생성
2. IAM Role 생성 (VPC Flow Logs → CloudWatch)
3. VPC Flow Logs 활성화:
```hcl
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

4. CloudWatch Logs 보존 기간 설정 (환경별 차별화)
   - Dev: 7일
   - Staging: 14일
   - Prod: 30일

**산출물**:
- VPC 모듈 업데이트 (Flow Logs)
- CloudWatch Logs Group

**소요 시간**: 25분

---

#### Phase 7: Systems Manager Session Manager (선택적)
**목표**: Bastion 호스트 대신 Session Manager로 안전한 SSH 접근

**작업 내용**:
1. SSM Agent가 EC2에 사전 설치되어 있는지 확인
2. IAM Role에 SSM 권한 추가:
```hcl
data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}
```

3. Bastion 인스턴스 제거 또는 유지 (선택)
4. Session Manager를 통한 접근 테스트

**장점**:
- SSH 키 관리 불필요
- Security Group에서 SSH 포트(22) 제거 가능
- 모든 세션이 CloudTrail에 기록됨

**산출물**:
- IAM Role 업데이트 (SSM 권한)
- Bastion 제거 또는 SSH 포트 닫기

**소요 시간**: 30분

---

## 4. 환경별 보안 설정 차이

### 4.1 Dev 환경

| 보안 설정 | Dev 환경 | 이유 |
|-----------|----------|------|
| Secrets Manager | ✅ 적용 | 보안 습관 형성 |
| IAM Role | ✅ 적용 | 권한 관리 학습 |
| Security Group | 제한적 (관리자 IP만) | 개발 편의성 |
| RDS 암호화 | ✅ 적용 (선택적 KMS) | 암호화 연습 |
| S3 암호화 | ✅ 적용 | 필수 |
| HTTPS | ⚠️ 선택적 | 도메인 없으면 생략 |
| VPC Flow Logs | ✅ 적용 (7일 보존) | 트래픽 분석 학습 |
| CloudTrail | ⚠️ 선택적 | 비용 고려 |

### 4.2 Staging 환경

| 보안 설정 | Staging 환경 | 이유 |
|-----------|--------------|------|
| Secrets Manager | ✅ 필수 | Prod 사전 검증 |
| IAM Role | ✅ 필수 | Prod 동일 구성 |
| Security Group | 엄격 (최소 권한) | Prod 미러링 |
| RDS 암호화 | ✅ 필수 (KMS) | Prod 동일 |
| S3 암호화 | ✅ 필수 (KMS) | Prod 동일 |
| HTTPS | ✅ 필수 | Prod 검증 |
| VPC Flow Logs | ✅ 필수 (14일 보존) | 문제 추적 |
| CloudTrail | ✅ 권장 | 감사 로그 |

### 4.3 Prod 환경

| 보안 설정 | Prod 환경 | 이유 |
|-----------|-----------|------|
| Secrets Manager | ✅ 필수 | 보안 기본 |
| IAM Role | ✅ 필수 | 최소 권한 |
| Security Group | 매우 엄격 | 공격 표면 최소화 |
| RDS 암호화 | ✅ 필수 (KMS, 자동 로테이션) | 데이터 보호 |
| S3 암호화 | ✅ 필수 (KMS, Versioning) | State 보호 |
| HTTPS | ✅ 필수 | 전송 중 암호화 |
| VPC Flow Logs | ✅ 필수 (30일 보존) | 보안 감사 |
| CloudTrail | ✅ 필수 | 규정 준수 |
| GuardDuty | ✅ 권장 | 위협 탐지 |
| AWS WAF | ✅ 권장 | 웹 공격 방어 |

---

## 5. 리스크 관리 (Risk Management)

### 5.1 Secrets Manager 도입 리스크

**리스크**: Terraform이 Secrets Manager에 접근 실패 시 RDS 생성 불가

**완화 전략**:
- Terraform에 Secrets Manager 읽기 권한 부여
- `depends_on`으로 시크릿 생성 후 RDS 생성 보장
- 시크릿 값 변경 시 RDS 재생성 방지 (`ignore_changes`)

**대응 방안**:
```hcl
lifecycle {
  ignore_changes = [password]
}
```

### 5.2 Security Group 과도한 제한 리스크

**리스크**: SSH 접근을 특정 IP로 제한 시 원격 작업 불가

**완화 전략**:
- 관리자 IP를 변수로 관리 (`admin_ip_ranges`)
- VPN 또는 Systems Manager Session Manager 병행
- 긴급 시 Security Group 규칙 임시 추가 절차 문서화

**대응 방안**:
- Session Manager를 기본 접근 방식으로 사용
- SSH는 비상시만 사용

### 5.3 암호화로 인한 성능 저하 리스크

**리스크**: KMS 암호화로 인한 RDS/S3 성능 영향

**완화 전략**:
- AWS 관리형 암호화 (`aws:kms`) 사용 (성능 최적화됨)
- Prod 환경에서 성능 테스트 실시

**대응 방안**:
- 성능 문제 발생 시 KMS 대신 `AES256` 사용 고려

### 5.4 HTTPS 설정 복잡도 리스크

**리스크**: 도메인 및 인증서 관리 복잡도 증가

**완화 전략**:
- LocalStack 환경에서는 HTTPS 생략 가능
- 실제 AWS에서만 ACM 인증서 사용
- 자체 서명 인증서로 학습 가능

**대응 방안**:
- 학습 단계에서는 HTTP만 사용
- Prod 환경에서만 HTTPS 필수화

---

## 6. 일정 (Timeline)

| Phase | 작업 내용 | 예상 시간 | 산출물 |
|-------|-----------|-----------|--------|
| Phase 1 | Secrets Manager 통합 | 30분 | secrets 모듈, RDS 업데이트 |
| Phase 2 | IAM Role 설정 | 40분 | iam 모듈, Compute 업데이트 |
| Phase 3 | Security Group 최적화 | 20분 | SG 모듈 업데이트 |
| Phase 4 | 데이터 암호화 (RDS, S3) | 40분 | kms 모듈, 암호화 설정 |
| Phase 5 | HTTPS 설정 (선택적) | 30분 | ACM, ALB HTTPS |
| Phase 6 | VPC Flow Logs | 25분 | VPC 모듈 업데이트 |
| Phase 7 | Session Manager (선택적) | 30분 | IAM 업데이트, Bastion 제거 |
| **총 예상 시간** | | **3시간 35분** | |

---

## 7. 보안 체크리스트

### 7.1 필수 항목 (Must-Have)

- [ ] DB 비밀번호를 Secrets Manager로 이전
- [ ] IAM Role 생성 및 EC2에 연결
- [ ] Security Group SSH 접근 제한 (관리자 IP만)
- [ ] RDS 저장 시 암호화 활성화
- [ ] S3 Backend 버킷 암호화
- [ ] VPC Flow Logs 활성화
- [ ] 모든 변경사항 Terraform 코드화
- [ ] Dev, Staging, Prod 모두 적용

### 7.2 권장 항목 (Should-Have)

- [ ] HTTPS 설정 (Prod 환경 필수)
- [ ] KMS 커스텀 키 사용
- [ ] CloudWatch Logs 보존 기간 설정
- [ ] Session Manager 활성화
- [ ] Bastion 제거 또는 SSH 포트 닫기

### 7.3 선택 항목 (Nice-to-Have)

- [ ] AWS GuardDuty 활성화 (위협 탐지)
- [ ] AWS WAF 설정 (웹 공격 방어)
- [ ] CloudTrail 감사 로그
- [ ] Config Rules (규정 준수 확인)
- [ ] Security Hub (통합 보안 대시보드)

---

## 8. 비용 영향 분석

### 8.1 추가 비용 발생 항목

| 서비스 | 예상 비용 (월) | 환경별 적용 |
|--------|----------------|-------------|
| Secrets Manager | $0.40/시크릿 × 3 = $1.20 | 모든 환경 |
| KMS | $1/키 × 2 = $2.00 | 모든 환경 |
| VPC Flow Logs (CloudWatch) | ~$0.50/GB | 모든 환경 (Dev: 최소, Prod: 중간) |
| ACM 인증서 | **무료** | Staging, Prod |
| CloudTrail | $2.00/월 | Prod만 (선택적) |
| GuardDuty | $4.00/계정 | Prod만 (선택적) |
| **총 추가 비용** | **~$4-10/월** | LocalStack은 무료 |

**참고**: LocalStack 환경에서는 추가 비용 없음

### 8.2 비용 절감 항목

- Session Manager 사용 시 Bastion 인스턴스 제거 → **~$10/월 절감**
- NAT Gateway 제거 가능 (Session Manager 사용 시) → **~$30/월 절감** (선택적)

---

## 9. 다음 단계 (Next Steps)

### 9.1 이번 단계 완료 후
1. ✅ 보안이 강화된 3-Tier 인프라
2. ✅ 민감 정보 안전 관리 (Secrets Manager)
3. ✅ 최소 권한 원칙 적용 (IAM Role, Security Group)
4. ✅ 데이터 암호화 (저장 시/전송 중)
5. ✅ 네트워크 트래픽 모니터링 (VPC Flow Logs)

### 9.2 향후 확장 가능 항목
- **Step 6**: Disaster Recovery (백업, 스냅샷, Cross-Region 복제)
- **Step 7**: Monitoring & Logging (CloudWatch 대시보드, 알림)
- **Step 8**: CI/CD 파이프라인 (GitHub Actions, Terraform Cloud)
- **Step 9**: Terraform 모듈 고도화 (Module Registry, Versioning)

---

## 10. 참고 자료 (References)

### 10.1 AWS 공식 문서
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

### 10.2 Terraform 문서
- [aws_secretsmanager_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
- [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)
- [aws_flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log)

### 10.3 보안 프레임워크
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)

### 10.4 내부 문서
- [Step 1 - Infrastructure Expansion](20260130-infrastructure-expansion.plan.md)
- [Step 2 - Infrastructure Modulization](20260130-infrastructure-modulization.plan.md)
- [Step 3 - LocalStack Deployment](20260130-localstack-deployment.plan.md)
- [Step 4 - Multi-Environment Setup](20260130-multi-environment-setup.plan.md)

---

## 11. 변경 이력 (Change Log)

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2026-01-30 | 1.0 | 초안 작성 - Security Hardening 계획 수립 | Claude Code |

---

**다음 문서**: [Design - Security Hardening](../../02-design/features/20260130-security-hardening.design.md)
