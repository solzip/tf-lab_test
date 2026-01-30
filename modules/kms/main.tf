# modules/kms/main.tf

# RDS 암호화용 KMS Key
resource "aws_kms_key" "rds" {
  description             = "${var.project_name} ${var.env_name} RDS encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.env_name}-rds-key"
      Environment = var.env_name
      Purpose     = "RDS Encryption"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.env_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# S3 Backend 암호화용 KMS Key
resource "aws_kms_key" "s3" {
  description             = "${var.project_name} ${var.env_name} S3 encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.env_name}-s3-key"
      Environment = var.env_name
      Purpose     = "S3 Encryption"
    }
  )
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.env_name}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# EBS 볼륨 암호화용 KMS Key (선택적)
resource "aws_kms_key" "ebs" {
  count = var.create_ebs_key ? 1 : 0

  description             = "${var.project_name} ${var.env_name} EBS encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.env_name}-ebs-key"
      Environment = var.env_name
      Purpose     = "EBS Encryption"
    }
  )
}

resource "aws_kms_alias" "ebs" {
  count = var.create_ebs_key ? 1 : 0

  name          = "alias/${var.project_name}-${var.env_name}-ebs"
  target_key_id = aws_kms_key.ebs[0].key_id
}
