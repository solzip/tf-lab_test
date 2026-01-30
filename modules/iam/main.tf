# modules/iam/main.tf

# EC2 인스턴스 Role (App 서버용)
resource "aws_iam_role" "ec2_app" {
  name = "${var.project_name}-${var.env_name}-ec2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.env_name}-ec2-app-role"
      Environment = var.env_name
      ManagedBy   = "Terraform"
    }
  )
}

# Secrets Manager 읽기 권한
resource "aws_iam_role_policy" "secrets_read" {
  name = "secrets-manager-read"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_arns
      }
    ]
  })
}

# S3 읽기 권한 (애플리케이션 에셋)
resource "aws_iam_role_policy" "s3_read" {
  count = var.enable_s3_access ? 1 : 0
  name  = "s3-read-access"
  role  = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.env_name}-assets",
          "arn:aws:s3:::${var.project_name}-${var.env_name}-assets/*"
        ]
      }
    ]
  })
}

# CloudWatch Logs 쓰기 권한
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "cloudwatch-logs-write"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Systems Manager Session Manager 권한 (선택적)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  count      = var.enable_session_manager ? 1 : 0
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile 생성
resource "aws_iam_instance_profile" "ec2_app" {
  name = "${var.project_name}-${var.env_name}-ec2-app-profile"
  role = aws_iam_role.ec2_app.name

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.env_name}-ec2-app-profile"
      Environment = var.env_name
    }
  )
}

# Bastion 호스트 Role (최소 권한)
resource "aws_iam_role" "ec2_bastion" {
  count = var.create_bastion_role ? 1 : 0
  name  = "${var.project_name}-${var.env_name}-ec2-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.env_name}-ec2-bastion-role"
      Environment = var.env_name
    }
  )
}

# Bastion Instance Profile
resource "aws_iam_instance_profile" "ec2_bastion" {
  count = var.create_bastion_role ? 1 : 0
  name  = "${var.project_name}-${var.env_name}-ec2-bastion-profile"
  role  = aws_iam_role.ec2_bastion[0].name
}
