# loadbalancer.tf
# Application Load Balancer 구성
#
# 목적:
# - 인터넷 트래픽을 Private Subnet의 EC2 인스턴스로 분산
# - Health Check로 정상 인스턴스만 트래픽 전달
# - Multi-AZ 구성으로 고가용성 확보
#
# 구성 요소:
# 1. Application Load Balancer: Public Subnet에 배치
# 2. Target Group: EC2 인스턴스 그룹
# 3. Listener: HTTP(80) 트래픽 수신
#
# 트래픽 흐름:
# Internet → ALB (Public) → Target Group → EC2 (Private)

# ---------------------------------------------------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------------------------------------------------

# Application Load Balancer
# - Public Subnet에 배치 (인터넷 접근 가능)
# - Multi-AZ 구성 (모든 Public Subnet에 배포)
# - ALB Security Group으로 HTTP/HTTPS만 허용
#
# 특징:
# - Layer 7 (HTTP/HTTPS) 로드 밸런싱
# - Path-based, Host-based 라우팅 지원
# - WebSocket, HTTP/2 지원
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.env_name}-alb"
  internal           = false # 인터넷 연결형 (Public)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id # 모든 Public Subnet

  # 삭제 방지 (운영 환경에서는 true 권장)
  enable_deletion_protection = false # 학습용이므로 false

  # 접근 로그 (선택)
  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "alb"
  #   enabled = true
  # }

  # Connection Draining (선택)
  # 인스턴스가 제거될 때 기존 연결을 안전하게 종료하는 시간
  # enable_cross_zone_load_balancing = true
  # idle_timeout = 60

  tags = {
    Name = "${var.project_name}-${var.env_name}-alb"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Target Group
# ---------------------------------------------------------------------------------------------------------------------

# Target Group
# - ALB가 트래픽을 전달할 대상 그룹
# - Auto Scaling Group이 자동으로 인스턴스를 등록/해제
# - Health Check로 정상 인스턴스만 트래픽 수신
#
# Health Check 동작:
# - 정상: 연속 2회(healthy_threshold) 성공 → Healthy
# - 비정상: 연속 2회(unhealthy_threshold) 실패 → Unhealthy
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-${var.env_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Target 타입 (인스턴스)
  target_type = "instance"

  # Health Check 설정
  health_check {
    enabled             = true
    healthy_threshold   = 2   # 2회 연속 성공 시 정상
    unhealthy_threshold = 2   # 2회 연속 실패 시 비정상
    timeout             = 5   # Health Check 타임아웃 (초)
    interval            = 30  # Health Check 간격 (초)
    path                = "/" # Health Check 경로
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200" # 성공 응답 코드
  }

  # Deregistration Delay (연결 종료 대기 시간)
  # - 인스턴스가 Target Group에서 제거될 때 기존 연결을 안전하게 종료
  deregistration_delay = 30

  # Stickiness (세션 고정) - 선택
  # - 동일 클라이언트를 동일 인스턴스로 라우팅
  # stickiness {
  #   type            = "lb_cookie"
  #   cookie_duration = 86400  # 1일
  #   enabled         = true
  # }

  tags = {
    Name = "${var.project_name}-${var.env_name}-tg"
  }

  # 생명주기 설정
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Listener
# ---------------------------------------------------------------------------------------------------------------------

# HTTP Listener (Port 80)
# - ALB로 들어오는 HTTP(80) 트래픽 수신
# - Target Group으로 트래픽 전달
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # 기본 동작: Target Group으로 전달
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTPS Listener (Port 443) - 선택
# - SSL/TLS 인증서 필요
# - ACM(AWS Certificate Manager)에서 인증서 발급
#
# 사용 예:
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = var.ssl_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }

# HTTP to HTTPS Redirect (선택)
# - HTTP 트래픽을 HTTPS로 리다이렉트
#
# 사용 예:
# resource "aws_lb_listener" "http_redirect" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"
#
#   default_action {
#     type = "redirect"
#
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# Listener Rules (선택)
# ---------------------------------------------------------------------------------------------------------------------

# Path-based Routing 예시
# - 경로에 따라 다른 Target Group으로 라우팅
#
# resource "aws_lb_listener_rule" "api" {
#   listener_arn = aws_lb_listener.http.arn
#   priority     = 100
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.api.arn
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/*"]
#     }
#   }
# }

# Host-based Routing 예시
# - 도메인에 따라 다른 Target Group으로 라우팅
#
# resource "aws_lb_listener_rule" "subdomain" {
#   listener_arn = aws_lb_listener.http.arn
#   priority     = 200
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.subdomain.arn
#   }
#
#   condition {
#     host_header {
#       values = ["subdomain.example.com"]
#     }
#   }
# }
