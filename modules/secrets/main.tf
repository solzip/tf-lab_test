# modules/secrets/main.tf

# RDS 마스터 비밀번호 시크릿
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "${var.project_name}-${var.env_name}-db-password-"
  description = "RDS master password for ${var.env_name} environment"

  recovery_window_in_days = var.env_name == "prod" ? 30 : 7

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.env_name}-db-password"
      Environment = var.env_name
      ManagedBy   = "Terraform"
      Rotation    = var.enable_rotation ? "enabled" : "disabled"
    }
  )
}

# 시크릿 값 저장
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = var.db_master_password
    engine   = "mysql"
    host     = var.db_endpoint
    port     = 3306
  })

  lifecycle {
    ignore_changes = [secret_string] # Terraform이 비밀번호 변경을 무시
  }
}

# 자동 로테이션 설정 (Prod 환경)
resource "aws_secretsmanager_secret_rotation" "db_password" {
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = 30
  }
}
