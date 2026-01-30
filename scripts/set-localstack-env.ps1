<#
.SYNOPSIS
  LocalStack + Terraform(S3 backend) 실행에 필요한 AWS 환경변수를 현재 PowerShell 세션에 설정한다.

.DESCRIPTION
  Terraform S3 backend는 provider 설정과 별개로 AWS SDK 자격증명을 요구한다.
  LocalStack에서는 실제 유효한 자격증명이 필요하지 않지만, AWS SDK가 요구하므로 더미 값을 세팅한다.

  이 스크립트는 "현재 세션"의 $env:*만 설정한다.
  새 터미널을 열면 다시 실행해야 한다.

.USAGE
  # 현재 세션에 반영하려면 dot-source로 실행해야 한다.
  . .\scripts\set-localstack-env.ps1

  # 또는 값 커스터마이징
  . .\scripts\set-localstack-env.ps1 -Region "ap-northeast-2" -AccessKey "test" -SecretKey "test"

  # p

#>

param(
    [string]$Region = "ap-northeast-2",
    [string]$AccessKey = "test",
    [string]$SecretKey = "test",
    [string]$SessionToken = "test",
    [switch]$DisableImds = $true
)

$env:AWS_ACCESS_KEY_ID     = $AccessKey
$env:AWS_SECRET_ACCESS_KEY = $SecretKey
$env:AWS_SESSION_TOKEN     = $SessionToken
$env:AWS_DEFAULT_REGION    = $Region

if ($DisableImds) {
    $env:AWS_EC2_METADATA_DISABLED = "true"
}

Write-Host "AWS env set for LocalStack (current session only)"
Write-Host ("AWS_ACCESS_KEY_ID=" + $env:AWS_ACCESS_KEY_ID)
Write-Host ("AWS_DEFAULT_REGION=" + $env:AWS_DEFAULT_REGION)
Write-Host ("AWS_EC2_METADATA_DISABLED=" + $env:AWS_EC2_METADATA_DISABLED)