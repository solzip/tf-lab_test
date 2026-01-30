#!/bin/bash
# User Data 스크립트 - Apache 웹 서버 설치

# 시스템 업데이트
yum update -y

# Apache 설치
yum install -y httpd

# Apache 시작 및 자동 시작 설정
systemctl start httpd
systemctl enable httpd

# 인스턴스 메타데이터 조회
if command -v ec2-metadata &> /dev/null; then
  INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
  AZ=$(ec2-metadata --availability-zone | cut -d " " -f 2)
else
  INSTANCE_ID="localstack-instance"
  AZ="localstack-az"
fi

# 웹 페이지 생성
cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>TF Lab - Modularized</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 50px;
      background-color: #f0f0f0;
    }
    .container {
      background-color: white;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    h1 { color: #333; }
    .badge {
      background-color: #4CAF50;
      color: white;
      padding: 5px 10px;
      border-radius: 5px;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 Hello from Modular Terraform!</h1>
    <span class="badge">Module-based Architecture</span>
    <div style="margin-top: 20px;">
      <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
      <p><strong>Availability Zone:</strong> $AZ</p>
      <p><strong>Environment:</strong> Local (LocalStack)</p>
      <p><strong>Architecture:</strong> 3-Tier Modular</p>
    </div>
  </div>
</body>
</html>
HTML

# Health Check 엔드포인트
echo "OK" > /var/www/html/health
