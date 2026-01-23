# main.tf
# VPC 기본 네트워크 구성 + 인터넷 게이트웨이 + 퍼블릭 라우팅 + 보안그룹을 생성한다.
#
# 구성 개요
# - VPC (DNS hostnames/support 활성화)
# - Internet Gateway (VPC에 부착)
# - Public Subnet N개 (각 AZ에 1개씩, 인스턴스 생성 시 Public IP 자동 할당)
# - Public Route Table + 0.0.0.0/0 -> IGW 기본 라우트
# - Route Table Association (모든 Public Subnet에 Public RT 연결)
# - Security Group (HTTP 80, SSH 22 인바운드 허용 / egress all)
#
# 주의사항(운영)
# - SSH(22)를 0.0.0.0/0로 오픈하면 보안 위험이 크다.
#   운영 환경에서는 관리자 고정 IP 또는 VPN/배스천을 권장한다.
# - Public Subnet을 다중 AZ로 구성하면 단일 AZ 장애에 대한 내성이 향상된다.
# - 보안그룹 인바운드 규칙은 최소 권한(필요 포트/필요 CIDR만 허용) 원칙을 적용한다.

# ---------------------------------------------------------------------------------------------------------------------

# VPC 생성
# - cidr_block: VPC 대역(예: 10.10.0.0/16)
# - enable_dns_hostnames/enable_dns_support: 퍼블릭 DNS 이름 사용 및 AWS DNS 해석 지원
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 태그 네이밍 규칙: <project>-<env>-<resource>
  tags = {
    Name = "${var.project_name}-${var.env_name}-vpc"
  }
}

# Internet Gateway 생성 및 VPC에 연결
# - Public Subnet이 인터넷과 통신하려면 IGW가 필요
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.env_name}-igw"
  }
}

# Public Subnet 생성 (다중)
# - var.public_subnet_cidrs 와 var.azs 는 길이가 동일해야 한다.
# - index 기준으로 CIDR <-> AZ가 1:1로 매핑된다.
# - map_public_ip_on_launch=true: 해당 서브넷에 생성되는 인스턴스에 Public IP 자동 할당
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.env_name}-public-subnet-${count.index + 1}"
  }
}

# Public Route Table 생성
# - 퍼블릭 서브넷이 사용할 라우팅 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.env_name}-public-rt"
  }
}

# 기본 라우트(인터넷 경로) 추가
# - 0.0.0.0/0 트래픽을 IGW로 라우팅하여 인터넷 통신 가능하게 함
resource "aws_route" "default_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Public Subnet에 Public Route Table 연결 (다중)
# - 모든 public subnet에 동일한 public route table을 연결한다.
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 웹/접속용 Security Group 생성
# - 인바운드: HTTP(80), SSH(22)
# - 아웃바운드: 전체 허용
#
# 주의사항
# - 운영에서는 SSH(22) 접근 CIDR을 제한하는 것을 권장한다.
resource "aws_security_group" "web" {
  name   = "${var.project_name}-${var.env_name}-web-sg"
  vpc_id = aws_vpc.main.id

  # HTTP 인바운드 허용
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH 인바운드 허용 (운영에서는 CIDR 제한 권장)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 전체 허용
  egress {
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.env_name}-web-sg"
  }
}