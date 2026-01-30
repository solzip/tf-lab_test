# modules/rds/main.tf
# RDS 모듈

################################################################################
# Secrets Manager Integration (Optional)
################################################################################

# Secrets Manager에서 비밀번호 조회 (secret_arn이 제공된 경우)
data "aws_secretsmanager_secret_version" "db_password" {
  count     = var.secret_arn != "" ? 1 : 0
  secret_id = var.secret_arn
}

locals {
  # Secrets Manager 사용 시 JSON에서 password 추출, 아니면 변수 사용
  db_credentials = var.secret_arn != "" ? jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string) : null
  db_password    = local.db_credentials != null ? local.db_credentials.password : var.db_password
  db_username    = local.db_credentials != null ? local.db_credentials.username : var.db_username
}

################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.env_name}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.env_name}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.env_name}-db-params"
  family = var.db_parameter_group_family

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  tags = {
    Name = "${var.project_name}-${var.env_name}-db-params"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.env_name}-db"

  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  max_allocated_storage = 100
  storage_type         = "gp3"

  # 저장 시 암호화 (KMS)
  storage_encrypted = var.enable_encryption
  kms_key_id        = var.enable_encryption && var.kms_key_arn != "" ? var.kms_key_arn : null

  db_name  = var.db_name
  username = local.db_username
  password = local.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az = var.db_multi_az

  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  copy_tags_to_snapshot     = true
  maintenance_window        = "mon:04:00-mon:05:00"
  auto_minor_version_upgrade = true

  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-${var.env_name}-final-snapshot"
  deletion_protection       = false
  publicly_accessible       = false

  tags = {
    Name        = "${var.project_name}-${var.env_name}-rds"
    Encryption  = var.enable_encryption ? "Enabled" : "Disabled"
    KMSKey      = var.kms_key_arn != "" ? "Custom" : "AWS Managed"
    SecretsMgr  = var.secret_arn != "" ? "Enabled" : "Disabled"
  }

  lifecycle {
    ignore_changes = [password]
  }
}
