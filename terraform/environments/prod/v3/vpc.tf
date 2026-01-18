# =============================================================================
# VPC 및 네트워크 리소스
# =============================================================================

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Elastic IP for NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

# Public Subnet (ALB, NLB, NAT Gateway)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet"
    Environment = var.environment
    Type        = "Public"
  }
}

# Private Subnet - Production (API, Web, AI-Agent EC2)
resource "aws_subnet" "private_prod" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-prod-subnet"
    Environment = var.environment
    Type        = "Private"
    Purpose     = "Production"
  }
}

# Private Subnet - Data (RDS, ElastiCache)
resource "aws_subnet" "private_data" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-data-subnet"
    Environment = var.environment
    Type        = "Private"
    Purpose     = "Data"
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway (Private Subnet의 외부 통신용)
# -----------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
  }
}

# Private Route Table (NAT Gateway를 통한 외부 통신)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_prod" {
  subnet_id      = aws_subnet.private_prod.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data" {
  subnet_id      = aws_subnet.private_data.id
  route_table_id = aws_route_table.private.id
}
