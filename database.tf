# database.tf
# RDS 데이터베이스 구성
#
# 목적:
# - Private DB Subnet에 RDS MySQL 인스턴스 배포
# - Multi-AZ 구성으로 고가용성 확보
# - 자동 백업 및 유지보수 윈도우 설정
#
# 구성 요소:
# 1. DB Subnet Group: RDS가 배포될 서브넷 그룹
# 2. DB Parameter Group: MySQL 파라미터 설정
# 3. RDS Instance: MySQL 데이터베이스 인스턴스
#
# 보안:
# - Private Subnet에 배치 (외부 접근 차단)
# - DB Security Group으로 App SG에서만 접근 허용
# - 패스워드는 Secrets Manager 사용 권장

# ---------------------------------------------------------------------------------------------------------------------
# DB Subnet Group
# ---------------------------------------------------------------------------------------------------------------------

# DB Subnet Group
# - RDS가 배포될 서브넷 그룹
# - Multi-AZ 배포를 위해 최소 2개 AZ의 서브넷 필요
# - Private DB Subnet만 사용
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.env_name}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  description = "DB subnet group for ${var.project_name}-${var.env_name}"

  tags = {
    Name = "${var.project_name}-${var.env_name}-db-subnet-group"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DB Parameter Group
# ---------------------------------------------------------------------------------------------------------------------

# DB Parameter Group
# - MySQL 데이터베이스 파라미터 설정
# - 문자 인코딩, 타임존, 로그 설정 등 커스터마이징
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.env_name}-db-params"
  family = "mysql8.0" # MySQL 8.0 패밀리

  description = "Custom parameter group for ${var.project_name}-${var.env_name}"

  # Character Set: UTF-8 설정
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  # 한글 지원을 위한 추가 설정
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

  # Slow Query Log (성능 분석용) - 선택
  # parameter {
  #   name  = "slow_query_log"
  #   value = "1"
  # }
  #
  # parameter {
  #   name  = "long_query_time"
  #   value = "2"  # 2초 이상 쿼리 로깅
  # }

  # General Log (전체 쿼리 로깅) - 개발 환경에서만 사용
  # parameter {
  #   name  = "general_log"
  #   value = "0"  # 운영에서는 0 (성능 영향)
  # }

  tags = {
    Name = "${var.project_name}-${var.env_name}-db-params"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# RDS Instance
# ---------------------------------------------------------------------------------------------------------------------

# RDS MySQL Instance
# - Private DB Subnet에 배포
# - Multi-AZ 구성 (고가용성)
# - 자동 백업 및 유지보수 윈도우 설정
#
# 보안:
# - publicly_accessible = false (외부 접근 차단)
# - DB Security Group으로 App SG에서만 접근 허용
# - 패스워드는 변수로 관리 (Secrets Manager 권장)
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.env_name}-db"

  # 엔진 설정
  engine         = var.db_engine         # mysql
  engine_version = var.db_engine_version # 8.0.35

  # 인스턴스 클래스
  instance_class = var.db_instance_class # db.t3.micro

  # 스토리지 설정
  allocated_storage     = 20    # 초기 스토리지 (GB)
  max_allocated_storage = 100   # 자동 확장 최대 크기 (GB)
  storage_type          = "gp3" # General Purpose SSD (gp3)
  storage_encrypted     = false # LocalStack 제약으로 false, 운영에서는 true

  # 데이터베이스 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password # Secrets Manager 사용 권장

  # 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false # 외부 접근 차단

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.main.name

  # Multi-AZ 설정
  # - true: Primary와 Standby가 다른 AZ에 배포
  # - 장애 발생 시 자동 failover
  # - 비용은 2배
  multi_az = var.db_multi_az

  # 백업 설정
  backup_retention_period   = 7             # 백업 보관 기간 (일)
  backup_window             = "03:00-04:00" # 백업 시간 (UTC)
  copy_tags_to_snapshot     = true          # 스냅샷에 태그 복사
  skip_final_snapshot       = true          # 삭제 시 최종 스냅샷 생략 (학습용)
  final_snapshot_identifier = "${var.project_name}-${var.env_name}-final-snapshot"

  # 유지보수 윈도우
  maintenance_window         = "mon:04:00-mon:05:00" # 월요일 4-5시 (UTC)
  auto_minor_version_upgrade = true                  # 마이너 버전 자동 업그레이드

  # 삭제 방지
  deletion_protection = false # 학습용이므로 false, 운영에서는 true

  # 성능 인사이트 (선택)
  # enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  # performance_insights_enabled    = true
  # performance_insights_retention_period = 7

  tags = {
    Name = "${var.project_name}-${var.env_name}-rds"
  }

  # 생명주기 설정
  lifecycle {
    # prevent_destroy = true  # 운영 환경에서는 실수 삭제 방지
    ignore_changes = [
      password, # 패스워드 변경 무시 (Secrets Manager로 관리 시)
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# RDS Read Replica (선택)
# ---------------------------------------------------------------------------------------------------------------------

# Read Replica
# - 읽기 트래픽 분산
# - 읽기 성능 향상
# - 재해 복구용으로도 사용 가능
#
# 사용 예:
# resource "aws_db_instance" "read_replica" {
#   identifier             = "${var.project_name}-${var.env_name}-db-replica"
#   replicate_source_db    = aws_db_instance.main.identifier
#   instance_class         = var.db_instance_class
#   auto_minor_version_upgrade = true
#   publicly_accessible    = false
#   skip_final_snapshot    = true
#
#   tags = {
#     Name = "${var.project_name}-${var.env_name}-db-replica"
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# 주의사항 및 운영 팁
# ---------------------------------------------------------------------------------------------------------------------

# 1. 패스워드 관리:
#    - 코드에 하드코딩하지 말 것
#    - AWS Secrets Manager 사용 권장
#    - 정기적으로 패스워드 변경
#
#    예:
#    data "aws_secretsmanager_secret_version" "db_password" {
#      secret_id = "db-password"
#    }
#
#    password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]

# 2. 백업 및 복구:
#    - backup_retention_period: 최소 7일 이상
#    - 정기적으로 복구 테스트 수행
#    - Point-in-Time Recovery 활용
#
#    복구 명령:
#    aws rds restore-db-instance-to-point-in-time \
#      --source-db-instance-identifier <source> \
#      --target-db-instance-identifier <target> \
#      --restore-time <timestamp>

# 3. 모니터링:
#    - CloudWatch Metrics 활용
#    - Performance Insights 활성화
#    - Enhanced Monitoring 고려
#
#    주요 메트릭:
#    - CPUUtilization
#    - DatabaseConnections
#    - FreeableMemory
#    - ReadLatency / WriteLatency

# 4. 비용 최적화:
#    - 개발: db.t3.micro, Single-AZ
#    - 스테이징: db.t3.small, Multi-AZ
#    - 운영: db.r6g.large+, Multi-AZ
#    - Reserved Instance 고려 (1년/3년 약정 시 할인)

# 5. 보안:
#    - storage_encrypted = true (운영 필수)
#    - IAM Database Authentication 고려
#    - SSL/TLS 연결 강제
#    - Network ACL 추가 고려
