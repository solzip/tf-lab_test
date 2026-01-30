<#
.SYNOPSIS
  환경별 Terraform 배포 자동화 스크립트

.DESCRIPTION
  Dev, Staging, Prod 환경에 대해 Terraform 명령을 실행한다.
  환경 혼동을 방지하기 위한 안전 장치 포함.

.PARAMETER Environment
  배포 대상 환경 (dev, staging, prod)

.PARAMETER Action
  실행할 Terraform 명령 (init, plan, apply, destroy)

.PARAMETER AutoApprove
  자동 승인 플래그 (apply/destroy 시 프롬프트 생략)

.EXAMPLE
  .\scripts\deploy-env.ps1 -Environment dev -Action plan
  Dev 환경에 대해 terraform plan 실행

.EXAMPLE
  .\scripts\deploy-env.ps1 -Environment staging -Action apply
  Staging 환경에 terraform apply 실행 (프롬프트 표시)

.EXAMPLE
  .\scripts\deploy-env.ps1 -Environment dev -Action apply -AutoApprove
  Dev 환경에 terraform apply 자동 승인

.NOTES
  - LocalStack이 실행 중이어야 함
  - AWS 환경변수가 설정되어 있어야 함 (set-localstack-env.ps1)
  - Prod 배포 시 추가 확인 절차 있음
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [ValidateSet("init", "plan", "apply", "destroy", "output")]
    [string]$Action,

    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"
$envPath = "environments\$Environment"

################################################################################
# Helper Functions
################################################################################

function Write-Header {
    param([string]$Message)
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Yellow
    Write-Host "================================================`n" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "▶ $Message" -ForegroundColor Green
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning-Message {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

################################################################################
# Pre-flight Checks
################################################################################

Write-Header "Terraform Deployment - $Environment Environment"

# 환경 디렉토리 존재 확인
if (-not (Test-Path $envPath)) {
    Write-Error-Message "Environment directory not found: $envPath"
    exit 1
}

# LocalStack 실행 확인 (init/plan/apply 시)
if ($Action -in @("init", "plan", "apply")) {
    Write-Step "Checking LocalStack status..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4566/_localstack/health" -TimeoutSec 5
        Write-Success "LocalStack is running"
    } catch {
        Write-Error-Message "LocalStack is not running. Please start LocalStack first."
        Write-Host "Run: docker-compose up -d localstack" -ForegroundColor Gray
        exit 1
    }
}

# Prod 환경 배포 시 추가 확인
if ($Environment -eq "prod" -and $Action -in @("apply", "destroy") -and -not $AutoApprove) {
    Write-Warning-Message "You are about to $Action resources in PRODUCTION environment!"
    Write-Host "This action can affect live services and user data." -ForegroundColor Yellow
    $confirm = Read-Host "`nType 'CONFIRM' to proceed, or anything else to cancel"

    if ($confirm -ne "CONFIRM") {
        Write-Host "`nProduction $Action cancelled by user." -ForegroundColor Gray
        exit 0
    }
}

################################################################################
# Environment Setup
################################################################################

Write-Step "Setting up environment..."

# 현재 위치 저장
$originalLocation = Get-Location

# 환경 디렉토리로 이동
Set-Location $envPath
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray

# AWS 환경변수 설정 (LocalStack용)
Write-Step "Loading AWS credentials for LocalStack..."
. ..\..\scripts\set-localstack-env.ps1

################################################################################
# Terraform Execution
################################################################################

try {
    switch ($Action) {
        "init" {
            Write-Header "Initializing Terraform Backend"
            Write-Host "Backend Config: backend.hcl" -ForegroundColor Gray

            terraform init -backend-config=backend.hcl -reconfigure

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Terraform initialization completed"
            } else {
                throw "Terraform init failed with exit code $LASTEXITCODE"
            }
        }

        "plan" {
            Write-Header "Planning Terraform Changes"
            Write-Host "Variables File: terraform.tfvars" -ForegroundColor Gray

            terraform plan -var-file=terraform.tfvars -out=tfplan

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Terraform plan completed"
                Write-Host "`nPlan saved to: tfplan" -ForegroundColor Gray
                Write-Host "To apply: .\scripts\deploy-env.ps1 -Environment $Environment -Action apply" -ForegroundColor Gray
            } else {
                throw "Terraform plan failed with exit code $LASTEXITCODE"
            }
        }

        "apply" {
            Write-Header "Applying Terraform Changes"

            # tfplan 파일 존재 확인
            if (Test-Path "tfplan") {
                Write-Host "Using saved plan: tfplan" -ForegroundColor Gray

                if ($AutoApprove) {
                    terraform apply tfplan
                } else {
                    terraform apply tfplan
                }
            } else {
                Write-Warning-Message "No saved plan found. Creating a new plan..."

                if ($AutoApprove) {
                    terraform apply -var-file=terraform.tfvars -auto-approve
                } else {
                    terraform apply -var-file=terraform.tfvars
                }
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Terraform apply completed successfully!"

                # tfplan 파일 삭제
                if (Test-Path "tfplan") {
                    Remove-Item "tfplan" -Force
                }

                Write-Host "`nTo view outputs: .\scripts\deploy-env.ps1 -Environment $Environment -Action output" -ForegroundColor Gray
            } else {
                throw "Terraform apply failed with exit code $LASTEXITCODE"
            }
        }

        "destroy" {
            Write-Header "Destroying Terraform Resources"
            Write-Warning-Message "This will destroy ALL resources in the $Environment environment!"

            if ($AutoApprove) {
                terraform destroy -var-file=terraform.tfvars -auto-approve
            } else {
                terraform destroy -var-file=terraform.tfvars
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Terraform destroy completed"
            } else {
                throw "Terraform destroy failed with exit code $LASTEXITCODE"
            }
        }

        "output" {
            Write-Header "Terraform Outputs"
            terraform output
        }
    }

} catch {
    Write-Error-Message "Error during Terraform execution: $_"
    exit 1
} finally {
    # 원래 위치로 복귀
    Set-Location $originalLocation
}

################################################################################
# Summary
################################################################################

Write-Header "Deployment Summary"
Write-Host "Environment:  $Environment" -ForegroundColor White
Write-Host "Action:       $Action" -ForegroundColor White
Write-Host "Status:       ✓ Success" -ForegroundColor Green
Write-Host ""
