# compute.tf
# EC2 인스턴스 및 Auto Scaling 구성
#
# 목적:
# - Private Subnet에 애플리케이션 서버(EC2) 배포
# - Auto Scaling Group으로 자동 확장/축소
# - Public Subnet에 Bastion Host 배포 (관리용)
#
# 구성 요소:
# 1. Launch Template: EC2 인스턴스 템플릿 정의
# 2. Auto Scaling Group: 자동 확장 그룹
# 3. Bastion Host: SSH 접근용 점프 서버
#
# 주의사항:
# - LocalStack에서는 실제 EC2 인스턴스 생성이 제한적
# - SSH 키는 실제 AWS에서 사전 생성 필요
# - AMI ID는 환경에 맞게 변경 필요

# ---------------------------------------------------------------------------------------------------------------------
# SSH Key Pair (선택)
# ---------------------------------------------------------------------------------------------------------------------

# SSH Key Pair
# - EC2 인스턴스 접속용 키
# - 실제 환경에서는 AWS Console이나 CLI로 미리 생성 권장
# - 또는 기존 키를 사용하도록 variables.tf에 key_name 추가
#
# 사용 예:
# resource "aws_key_pair" "main" {
#   key_name   = "${var.project_name}-${var.env_name}-key"
#   public_key = file("~/.ssh/id_rsa.pub")
#
#   tags = {
#     Name = "${var.project_name}-${var.env_name}-key"
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# Launch Template
# ---------------------------------------------------------------------------------------------------------------------

# Launch Template
# - Auto Scaling Group이 사용할 EC2 인스턴스 템플릿
# - AMI, 인스턴스 타입, Security Group, User Data 정의
# - User Data로 웹 서버 자동 설치 및 설정
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.env_name}-app-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # SSH Key (있을 경우)
  # key_name = aws_key_pair.main.key_name
  # 또는
  # key_name = var.key_name

  # 네트워크 인터페이스 설정
  network_interfaces {
    associate_public_ip_address = false # Private Subnet이므로 Public IP 불필요
    security_groups             = [aws_security_group.app.id]
    delete_on_termination       = true
  }

  # User Data - 인스턴스 시작 시 실행되는 스크립트
  # - Apache 웹 서버 설치
  # - 인스턴스 정보를 표시하는 HTML 페이지 생성
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # 시스템 업데이트
    yum update -y

    # Apache 웹 서버 설치
    yum install -y httpd

    # Apache 시작 및 부팅 시 자동 시작 설정
    systemctl start httpd
    systemctl enable httpd

    # 인스턴스 메타데이터 조회 (실제 AWS에서만 작동)
    # LocalStack에서는 더미 값 사용
    if command -v ec2-metadata &> /dev/null; then
      INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
      AZ=$(ec2-metadata --availability-zone | cut -d " " -f 2)
    else
      INSTANCE_ID="localstack-instance"
      AZ="localstack-az"
    fi

    # 간단한 웹 페이지 생성
    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>TF Lab App</title>
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
        .info { margin: 20px 0; }
        .label { font-weight: bold; color: #666; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Hello from Terraform Lab!</h1>
        <div class="info">
          <p class="label">Instance ID:</p>
          <p>$INSTANCE_ID</p>
        </div>
        <div class="info">
          <p class="label">Availability Zone:</p>
          <p>$AZ</p>
        </div>
        <div class="info">
          <p class="label">Environment:</p>
          <p>${var.env_name}</p>
        </div>
        <div class="info">
          <p class="label">Project:</p>
          <p>${var.project_name}</p>
        </div>
      </div>
    </body>
    </html>
    HTML

    # Health Check용 엔드포인트
    echo "OK" > /var/www/html/health
  EOF
  )

  # Tag Specifications - 인스턴스에 적용될 태그
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.env_name}-app-instance"
    }
  }

  # 생명주기 설정
  # - 새 버전 생성 시 기존 템플릿 유지 후 교체
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Auto Scaling Group
# ---------------------------------------------------------------------------------------------------------------------

# Auto Scaling Group
# - Launch Template을 사용하여 EC2 인스턴스 자동 생성
# - Private App Subnet에 인스턴스 배포
# - ALB Target Group에 자동 등록
# - Health Check를 통한 인스턴스 상태 모니터링
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-${var.env_name}-asg"
  vpc_zone_identifier = aws_subnet.private_app[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]

  # Health Check 설정
  health_check_type         = "ELB" # ALB Health Check 사용
  health_check_grace_period = 300   # 5분 (인스턴스 시작 후 대기 시간)

  # 용량 설정
  min_size         = var.asg_min_size         # 최소 인스턴스 수
  max_size         = var.asg_max_size         # 최대 인스턴스 수
  desired_capacity = var.asg_desired_capacity # 원하는 인스턴스 수

  # Launch Template 지정
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest" # 항상 최신 버전 사용
  }

  # 인스턴스에 전파될 태그
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.env_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "ASG"
    propagate_at_launch = true
  }

  # 생명주기 설정
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Auto Scaling Policy (선택)
# ---------------------------------------------------------------------------------------------------------------------

# Target Tracking Scaling Policy - CPU 기반 자동 확장
# - CPU 사용률이 70%를 넘으면 인스턴스 추가
# - CPU 사용률이 낮아지면 인스턴스 축소
resource "aws_autoscaling_policy" "cpu_tracking" {
  name                   = "${var.project_name}-${var.env_name}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # CPU 70% 목표
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Bastion Host
# ---------------------------------------------------------------------------------------------------------------------

# Bastion Host
# - Public Subnet에 배치
# - Private Subnet의 EC2 인스턴스에 SSH 접근용
# - 관리자만 접근 가능 (Bastion SG로 제어)
#
# 사용 방법:
# 1. Bastion에 SSH 접속
# 2. Bastion에서 Private EC2로 SSH 접속
#
# 주의사항:
# - LocalStack에서는 실제 SSH 접속 불가
# - 실제 AWS에서는 key_name 필수
resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[0].id # 첫 번째 Public Subnet

  vpc_security_group_ids = [aws_security_group.bastion.id]

  # SSH Key (있을 경우)
  # key_name = aws_key_pair.main.key_name
  # 또는
  # key_name = var.key_name

  # User Data - 기본 설정
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y

    # 유용한 도구 설치
    yum install -y vim htop tmux

    # SSH 설정 강화 (선택)
    # sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    # systemctl restart sshd
  EOF
  )

  tags = {
    Name = "${var.project_name}-${var.env_name}-bastion"
    Role = "Bastion"
  }

  # 생명주기 설정
  lifecycle {
    # prevent_destroy = true  # 운영 환경에서는 실수 삭제 방지
  }
}
