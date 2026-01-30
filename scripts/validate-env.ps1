<#
.SYNOPSIS
  환경별 배포 결과 검증

.DESCRIPTION
  Terraform 배포 후 리소스 상태, 출력 값, State 격리를 검증한다.

.PARAMETER Environment
  검증 대상 환경 (dev, staging, prod)

.EXAMPLE
  .\scripts\validate-env.ps1 -Environment dev

.NOTES
  - terraform이 초기화되어 있어야 함
  - AWS 환경변수 설정 필요
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment
)

$ErrorActionPreference = "Stop"
$envPath = "environments\$Environment"

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Validating $Environment Environment" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Cyan

# 환경 디렉토리로 이동
$originalLocation = Get-Location
Set-Location $envPath

# AWS 환경변수 설정
. ..\..\scripts\set-localstack-env.ps1

try {
    # 1. Terraform 출력 값 확인
    Write-Host "[1/4] Terraform Outputs" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────" -ForegroundColor Gray
    terraform output
    Write-Host ""

    # 2. State 파일 위치 확인
    Write-Host "[2/4] State File Location" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────" -ForegroundColor Gray
    $bucket = "tfstate-$Environment"
    $key = "tf-lab/$Environment/terraform.tfstate"

    Write-Host "Bucket: $bucket" -ForegroundColor White
    Write-Host "Key:    $key" -ForegroundColor White

    # State 파일 존재 확인
    $endpoint = "http://localhost:4566"
    aws s3 ls "s3://$bucket/tf-lab/$Environment/" --endpoint-url=$endpoint
    Write-Host ""

    # 3. 리소스 개수 확인
    Write-Host "[3/4] Resource Count" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────" -ForegroundColor Gray
    $resources = terraform state list
    Write-Host "Total resources: $($resources.Count)" -ForegroundColor Yellow
    Write-Host ""

    # 4. 주요 리소스 확인
    Write-Host "[4/4] Key Resources" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────" -ForegroundColor Gray

    $keyResources = @(
        "module.vpc.aws_vpc.main",
        "module.compute.aws_instance.bastion",
        "module.compute.aws_autoscaling_group.app",
        "module.alb.aws_lb.main",
        "module.rds.aws_db_instance.main"
    )

    foreach ($resource in $keyResources) {
        if ($resources -contains $resource) {
            Write-Host "✓ $resource" -ForegroundColor Green
        } else {
            Write-Host "✗ $resource (not found)" -ForegroundColor Red
        }
    }
    Write-Host ""

    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "✅ Validation Complete for $Environment" -ForegroundColor Green
    Write-Host "================================================`n" -ForegroundColor Cyan

} catch {
    Write-Host "✗ Validation failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $originalLocation
}
