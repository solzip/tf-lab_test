<#
.SYNOPSIS
  모든 환경의 Backend 인프라를 LocalStack에 생성

.DESCRIPTION
  Dev, Staging, Prod 환경의 S3 버킷과 DynamoDB 테이블을 LocalStack에 생성한다.
  각 환경은 완전히 독립적인 Backend 리소스를 가진다.

.USAGE
  .\scripts\init-backends.ps1

.NOTES
  - LocalStack 컨테이너가 실행 중이어야 함
  - AWS CLI 설치 필요
  - 환경변수 AWS_* 설정 필요 (set-localstack-env.ps1)
#>

$ErrorActionPreference = "Stop"

# AWS 환경변수 설정
Write-Host "Setting AWS environment variables..." -ForegroundColor Cyan
. .\scripts\set-localstack-env.ps1

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Creating Backend Infrastructure for All Environments" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Cyan

$environments = @("dev", "staging", "prod")
$endpoint = "http://localhost:4566"

foreach ($env in $environments) {
    Write-Host "──────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "Environment: $env" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────" -ForegroundColor Gray

    # S3 버킷 이름 및 DynamoDB 테이블 이름
    $bucket = "tfstate-$env"
    $table = "terraform-locks-$env"

    # S3 버킷 생성
    Write-Host "[1/3] Creating S3 bucket: $bucket" -ForegroundColor Green
    try {
        aws s3 mb "s3://$bucket" --endpoint-url=$endpoint 2>$null
        Write-Host "      ✓ Bucket created successfully" -ForegroundColor Green
    } catch {
        Write-Host "      ⚠ Bucket may already exist (ignoring error)" -ForegroundColor Yellow
    }

    # 버킷 버저닝 활성화
    Write-Host "[2/3] Enabling versioning for: $bucket" -ForegroundColor Green
    aws s3api put-bucket-versioning `
        --bucket $bucket `
        --versioning-configuration Status=Enabled `
        --endpoint-url=$endpoint
    Write-Host "      ✓ Versioning enabled" -ForegroundColor Green

    # DynamoDB 테이블 생성
    Write-Host "[3/3] Creating DynamoDB table: $table" -ForegroundColor Green
    try {
        aws dynamodb create-table `
            --table-name $table `
            --attribute-definitions AttributeName=LockID,AttributeType=S `
            --key-schema AttributeName=LockID,KeyType=HASH `
            --billing-mode PAY_PER_REQUEST `
            --endpoint-url=$endpoint 2>$null | Out-Null
        Write-Host "      ✓ Table created successfully" -ForegroundColor Green
    } catch {
        Write-Host "      ⚠ Table may already exist (ignoring error)" -ForegroundColor Yellow
    }

    Write-Host ""
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ All Backend Resources Created Successfully!" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan

# 생성된 리소스 확인
Write-Host "Verifying created resources..." -ForegroundColor Cyan
Write-Host "`nS3 Buckets:" -ForegroundColor Yellow
aws s3 ls --endpoint-url=$endpoint

Write-Host "`nDynamoDB Tables:" -ForegroundColor Yellow
aws dynamodb list-tables --endpoint-url=$endpoint --query 'TableNames' --output table
