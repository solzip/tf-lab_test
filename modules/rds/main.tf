# modules/rds/main.tf
# RDS 모듈

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
  storage_encrypted    = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

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
    Name = "${var.project_name}-${var.env_name}-rds"
  }

  lifecycle {
    ignore_changes = [password]
  }
}
