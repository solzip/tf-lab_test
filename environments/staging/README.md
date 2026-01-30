# Staging Environment

## 목적
프로덕션 배포 전 최종 검증 환경

## 특징
- Multi-AZ 구성 (고가용성)
- 중간 크기 인스턴스 타입 (t2.small)
- RDS Multi-AZ
- LocalStack Backend

## 배포 방법
```powershell
# Backend 초기화 (최초 1회)
.\scripts\init-backends.ps1

# Staging 환경 배포
.\scripts\deploy-env.ps1 -Environment staging -Action init
.\scripts\deploy-env.ps1 -Environment staging -Action plan
.\scripts\deploy-env.ps1 -Environment staging -Action apply

# 배포 검증
.\scripts\validate-env.ps1 -Environment staging
```

## 리소스 구성
- **VPC CIDR**: 10.1.0.0/16
- **Availability Zones**: ap-northeast-2a, ap-northeast-2c (2개)
- **Bastion**: t2.small
- **App Instance**: t2.small
- **ASG**: Min 2, Max 4, Desired 2
- **RDS**: db.t3.small, 50GB, Multi-AZ

## Backend 설정
- **S3 Bucket**: tfstate-staging
- **DynamoDB Table**: terraform-locks-staging
- **State Path**: tf-lab/staging/terraform.tfstate

## 주의사항
⚠️ 프로덕션과 동일한 구성으로 최종 테스트를 수행하세요
⚠️ 백업 보관 기간: 7일
