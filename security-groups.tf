# security-groups.tf
# Security Groups 통합 관리 파일
#
# 목적:
# - 계층별 보안 그룹을 한 곳에서 관리
# - Security Group 간 참조를 통한 계층 간 접근 제어
# - 최소 권한 원칙 적용
#
# Security Groups:
# 1. ALB SG: 인터넷에서 HTTP/HTTPS 접근 허용
# 2. Bastion SG: 관리자 IP에서 SSH 접근 허용
# 3. App SG: ALB에서 HTTP, Bastion에서 SSH 허용
# 4. DB SG: App SG에서만 MySQL 포트 접근 허용
#
# 보안 설계 원칙:
# - 인바운드는 필요한 포트만 오픈
# - 소스는 CIDR보다 SG 참조 우선 (계층 간 접근 제어)
# - 아웃바운드는 필요 시에만 제한 (DB는 아웃바운드 불필요)

# ---------------------------------------------------------------------------------------------------------------------
# ALB Security Group
# ---------------------------------------------------------------------------------------------------------------------

# Application Load Balancer Security Group
# - 인터넷에서 HTTP(80), HTTPS(443) 접근 허용
# - 아웃바운드: EC2 인스턴스로 포워딩 (전체 허용)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.env_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.env_name}-alb-sg"
  }
}

# ALB Ingress: HTTP from Internet
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  description       = "HTTP from Internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# ALB Ingress: HTTPS from Internet (선택)
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  description       = "HTTPS from Internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# ALB Egress: To EC2 instances
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  description       = "To EC2 instances"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Bastion Security Group
# ---------------------------------------------------------------------------------------------------------------------

# Bastion Host Security Group
# - 관리자 IP에서만 SSH 접근 허용
# - 아웃바운드: Private EC2에 SSH 연결 (전체 허용)
#
# 운영 환경 권장사항:
# - admin_ssh_cidrs를 고정 관리자 IP로 제한
# - VPN 또는 Corporate Network CIDR 사용
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.env_name}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.env_name}-bastion-sg"
  }
}

# Bastion Ingress: SSH from Admin
resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  description       = "SSH from Admin"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_ssh_cidrs
  security_group_id = aws_security_group.bastion.id
}

# Bastion Egress: All outbound
resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Application (EC2) Security Group
# ---------------------------------------------------------------------------------------------------------------------

# Application EC2 Security Group
# - ALB에서 HTTP 접근 허용
# - Bastion에서 SSH 접근 허용
# - 아웃바운드: 패키지 설치, RDS 연결 등 (전체 허용)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.env_name}-app-sg"
  description = "Security group for Application EC2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.env_name}-app-sg"
  }
}

# App Ingress: HTTP from ALB
# - source_security_group_id로 ALB SG 참조
# - CIDR 대신 SG 참조로 계층 간 접근 제어
resource "aws_security_group_rule" "app_ingress_http_from_alb" {
  type                     = "ingress"
  description              = "HTTP from ALB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}

# App Ingress: SSH from Bastion
resource "aws_security_group_rule" "app_ingress_ssh_from_bastion" {
  type                     = "ingress"
  description              = "SSH from Bastion"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.app.id
}

# App Egress: All outbound
# - NAT Gateway를 통한 외부 통신 (yum, apt, API 호출 등)
# - RDS 연결
resource "aws_security_group_rule" "app_egress_all" {
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Database (RDS) Security Group
# ---------------------------------------------------------------------------------------------------------------------

# Database RDS Security Group
# - App SG에서만 MySQL(3306) 접근 허용
# - 아웃바운드 불필요 (제한)
#
# 보안 강화:
# - Public 접근 완전 차단
# - 애플리케이션 계층에서만 접근
# - DB는 외부 통신 불필요
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.env_name}-db-sg"
  description = "Security group for RDS Database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.env_name}-db-sg"
  }
}

# DB Ingress: MySQL from App
resource "aws_security_group_rule" "db_ingress_mysql_from_app" {
  type                     = "ingress"
  description              = "MySQL from App"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}

# PostgreSQL 사용 시 (선택)
# resource "aws_security_group_rule" "db_ingress_postgres_from_app" {
#   type                     = "ingress"
#   description              = "PostgreSQL from App"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.app.id
#   security_group_id        = aws_security_group.db.id
# }

# DB Egress: 제한 없음 (외부 통신 불필요)
# - RDS는 아웃바운드 연결이 필요하지 않음
# - 보안 강화를 위해 egress를 정의하지 않음
# - 필요 시 명시적으로 추가
