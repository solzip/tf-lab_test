# Production Environment

## 목적
실제 서비스 운영 환경

## 특징
- Multi-AZ 고가용성 구성
- 큰 인스턴스 타입 (t3.medium)
- RDS Multi-AZ with 백업
- LocalStack (학습용) / AWS S3 (실제 운영)

## 배포 방법
```powershell
# Backend 초기화 (최초 1회)
.\scripts\init-backends.ps1

# ⚠️ WARNING: 프로덕션 배포 - 신중하게 진행
.\scripts\deploy-env.ps1 -Environment prod -Action init
.\scripts\deploy-env.ps1 -Environment prod -Action plan
.\scripts\deploy-env.ps1 -Environment prod -Action apply

# 배포 검증
.\scripts\validate-env.ps1 -Environment prod
```

## 리소스 구성
- **VPC CIDR**: 10.2.0.0/16
- **Availability Zones**: ap-northeast-2a, ap-northeast-2c (2개)
- **Bastion**: t3.small
- **App Instance**: t3.medium
- **ASG**: Min 2, Max 10, Desired 4
- **RDS**: db.t3.medium, 100GB, Multi-AZ

## Backend 설정
- **S3 Bucket**: tfstate-prod
- **DynamoDB Table**: terraform-locks-prod
- **State Path**: tf-lab/prod/terraform.tfstate

## 주의사항
🔴 **PRODUCTION 환경입니다!**
- 배포 전 반드시 Plan을 확인하세요
- 자동 승인(-AutoApprove) 사용 금지
- Destroy 명령은 절대 금지
- 백업 보관 기간: 14일
- RDS 삭제 보호 활성화
- Final Snapshot 생성 필수
