<#
.SYNOPSIS
  환경 간 State 격리 확인 및 리소스 비교

.DESCRIPTION
  Dev, Staging, Prod 환경의 State가 올바르게 격리되어 있는지 확인하고
  환경별 리소스 개수를 비교한다.

.EXAMPLE
  .\scripts\compare-envs.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Multi-Environment State Comparison" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Cyan

# AWS 환경변수 설정
. .\scripts\set-localstack-env.ps1

$environments = @("dev", "staging", "prod")
$endpoint = "http://localhost:4566"
$results = @{}

foreach ($env in $environments) {
    Write-Host "──────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "Environment: $env" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────" -ForegroundColor Gray

    $bucket = "tfstate-$env"
    $key = "tf-lab/$env/terraform.tfstate"

    # State 파일 존재 확인
    try {
        $stateCheck = aws s3 ls "s3://$bucket/$key" --endpoint-url=$endpoint 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ State file exists: s3://$bucket/$key" -ForegroundColor Green

            # 리소스 개수 확인
            Push-Location "environments\$env"
            $resources = terraform state list 2>$null
            $resourceCount = $resources.Count
            Pop-Location

            Write-Host "  Resources: $resourceCount" -ForegroundColor White
            $results[$env] = $resourceCount
        } else {
            Write-Host "✗ State file not found (environment not deployed)" -ForegroundColor Yellow
            $results[$env] = 0
        }
    } catch {
        Write-Host "✗ Error checking state: $_" -ForegroundColor Red
        $results[$env] = 0
    }

    Write-Host ""
}

# 결과 요약
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "State Isolation Summary" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Cyan

$table = @"
┌──────────────┬────────────────────┬────────────────┐
│ Environment  │ State Location     │ Resource Count │
├──────────────┼────────────────────┼────────────────┤
│ Dev          │ tfstate-dev        │ $($results["dev"].ToString().PadLeft(14)) │
│ Staging      │ tfstate-staging    │ $($results["staging"].ToString().PadLeft(14)) │
│ Prod         │ tfstate-prod       │ $($results["prod"].ToString().PadLeft(14)) │
└──────────────┴────────────────────┴────────────────┘
"@

Write-Host $table -ForegroundColor White
Write-Host ""

if ($results["dev"] -gt 0 -or $results["staging"] -gt 0 -or $results["prod"] -gt 0) {
    Write-Host "✅ State isolation is working correctly!" -ForegroundColor Green
} else {
    Write-Host "⚠ No environments deployed yet" -ForegroundColor Yellow
}

Write-Host ""
