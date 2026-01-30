# network-private.tf
# Private 네트워크 구성 (Private Subnet, NAT Gateway, Private Route Table)
#
# 목적:
# - Public Subnet과 분리된 Private 계층 구성
# - Private Subnet은 NAT Gateway를 통해 외부 통신 (인바운드는 차단)
# - 보안이 필요한 리소스(App, DB)를 Private Subnet에 배치
#
# 구성 요소:
# - Elastic IP for NAT Gateway
# - NAT Gateway (Public Subnet에 배치)
# - Private App Subnets (EC2 인스턴스용)
# - Private DB Subnets (RDS용)
# - Private Route Table (0.0.0.0/0 → NAT Gateway)

# ---------------------------------------------------------------------------------------------------------------------
# Elastic IP for NAT Gateway
# ---------------------------------------------------------------------------------------------------------------------

# NAT Gateway에 할당할 고정 Public IP
# - domain="vpc": VPC 전용 EIP
# - NAT Gateway는 외부 통신을 위해 Public IP 필요
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.env_name}-nat-eip"
  }

  # NAT Gateway보다 먼저 생성되어야 하므로 IGW 의존성 명시
  depends_on = [aws_internet_gateway.igw]
}

# ---------------------------------------------------------------------------------------------------------------------
# NAT Gateway
# ---------------------------------------------------------------------------------------------------------------------

# NAT Gateway
# - Private Subnet에서 외부로 나가는 트래픽을 처리
# - Public Subnet에 배치 (외부 통신 가능해야 함)
# - 단일 NAT Gateway 구성 (학습용, 비용 절감)
#
# 운영 환경 권장사항:
# - 각 AZ마다 NAT Gateway 배치 (가용성 향상)
# - 하지만 비용이 2배로 증가함
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # 첫 번째 Public Subnet에 배치

  tags = {
    Name = "${var.project_name}-${var.env_name}-nat-gw"
  }

  # Internet Gateway가 생성된 후 NAT Gateway 생성
  depends_on = [aws_internet_gateway.igw]
}

# ---------------------------------------------------------------------------------------------------------------------
# Private Application Subnets
# ---------------------------------------------------------------------------------------------------------------------

# Private Application Subnets
# - EC2 인스턴스(애플리케이션 서버)가 배치될 서브넷
# - Public IP 할당 안 함 (map_public_ip_on_launch = false)
# - NAT Gateway를 통해 외부 통신 (패키지 설치, API 호출 등)
# - Multi-AZ 구성으로 고가용성 확보
resource "aws_subnet" "private_app" {
  count                   = length(var.private_app_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false # Private이므로 Public IP 할당 안 함

  tags = {
    Name = "${var.project_name}-${var.env_name}-private-app-subnet-${count.index + 1}"
    Tier = "Application"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Private Database Subnets
# ---------------------------------------------------------------------------------------------------------------------

# Private Database Subnets
# - RDS 인스턴스가 배치될 서브넷
# - 외부 인터넷 통신 불필요 (애플리케이션 계층에서만 접근)
# - Multi-AZ 구성 (RDS Multi-AZ 배포 요구사항)
resource "aws_subnet" "private_db" {
  count                   = length(var.private_db_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_db_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.env_name}-private-db-subnet-${count.index + 1}"
    Tier = "Database"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Private Route Table
# ---------------------------------------------------------------------------------------------------------------------

# Private Route Table
# - Private Subnet들이 사용할 라우팅 테이블
# - 0.0.0.0/0 → NAT Gateway (외부 통신)
# - 10.10.0.0/16 → local (VPC 내부 통신, 자동 추가)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.env_name}-private-rt"
  }
}

# Private Route: 외부 트래픽을 NAT Gateway로 라우팅
# - destination_cidr_block = "0.0.0.0/0": 모든 외부 트래픽
# - nat_gateway_id: NAT Gateway를 통해 나감
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Route Table Associations
# ---------------------------------------------------------------------------------------------------------------------

# Private App Subnet과 Private Route Table 연결
# - 모든 Private App Subnet에 동일한 Private Route Table 적용
resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Private DB Subnet과 Private Route Table 연결
# - 모든 Private DB Subnet에 동일한 Private Route Table 적용
resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}
