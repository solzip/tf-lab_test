# Dev Environment

## 목적
개발자 테스트 및 기능 검증 환경

## 특징
- Single AZ 구성 (비용 최소화)
- 작은 인스턴스 타입 (t2.micro)
- RDS Single-AZ
- LocalStack Backend

## 배포 방법
```powershell
# Backend 초기화 (최초 1회)
.\scripts\init-backends.ps1

# Dev 환경 배포
.\scripts\deploy-env.ps1 -Environment dev -Action init
.\scripts\deploy-env.ps1 -Environment dev -Action plan
.\scripts\deploy-env.ps1 -Environment dev -Action apply

# 배포 검증
.\scripts\validate-env.ps1 -Environment dev
```

## 리소스 구성
- **VPC CIDR**: 10.0.0.0/16
- **Availability Zones**: ap-northeast-2a (1개)
- **Bastion**: t2.micro
- **App Instance**: t2.micro
- **ASG**: Min 1, Max 2, Desired 1
- **RDS**: db.t3.micro, 20GB, Single-AZ

## Backend 설정
- **S3 Bucket**: tfstate-dev
- **DynamoDB Table**: terraform-locks-dev
- **State Path**: tf-lab/dev/terraform.tfstate

## 주의사항
⚠️ 개발 환경이므로 데이터 보관 기간이 짧습니다 (백업 1일)
⚠️ Single AZ 구성으로 가용성이 제한적입니다
