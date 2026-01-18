# =============================================================================
# Security Groups
# =============================================================================

# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound - All
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# NLB Security Group (Livekit용)
# -----------------------------------------------------------------------------
resource "aws_security_group" "nlb" {
  name        = "${var.project_name}-${var.environment}-nlb-sg"
  description = "Security group for Network Load Balancer (Livekit)"
  vpc_id      = aws_vpc.main.id

  # WebRTC - TCP
  ingress {
    description = "WebRTC TCP from anywhere"
    from_port   = 7880
    to_port     = 7880
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WebRTC - UDP
  ingress {
    description = "WebRTC UDP from anywhere"
    from_port   = 50000
    to_port     = 60000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound - All
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-nlb-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# EC2 Security Group - AI Agent
# -----------------------------------------------------------------------------
resource "aws_security_group" "ai_agent" {
  name        = "${var.project_name}-${var.environment}-ai-agent-sg"
  description = "Security group for AI Agent EC2"
  vpc_id      = aws_vpc.main.id

  # Livekit agent 포트 (NLB로부터)
  ingress {
    description     = "Agent port from NLB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }

  # VPC 내부 통신 (API 서버와 통신용)
  ingress {
    description = "Internal VPC communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound - All
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ai-agent-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# EC2 Security Group - API Server
# -----------------------------------------------------------------------------
resource "aws_security_group" "api_server" {
  name        = "${var.project_name}-${var.environment}-api-server-sg"
  description = "Security group for API Server EC2"
  vpc_id      = aws_vpc.main.id

  # API port from ALB
  ingress {
    description     = "API port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # VPC 내부 통신
  ingress {
    description = "Internal VPC communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound - All
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-server-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# EC2 Security Group - Web Server
# -----------------------------------------------------------------------------
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-${var.environment}-web-server-sg"
  description = "Security group for Web Server EC2"
  vpc_id      = aws_vpc.main.id

  # Web port from ALB
  ingress {
    description     = "Web port from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # VPC 내부 통신
  ingress {
    description = "Internal VPC communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound - All
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-server-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# RDS Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL port from EC2 instances
  ingress {
    description     = "PostgreSQL from API server"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api_server.id]
  }

  ingress {
    description     = "PostgreSQL from AI agent"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ai_agent.id]
  }

  # Outbound - All
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# ElastiCache Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  # Redis port from EC2 instances
  ingress {
    description     = "Redis from API server"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.api_server.id]
  }

  ingress {
    description     = "Redis from AI agent"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ai_agent.id]
  }

  # Outbound - All
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-sg"
    Environment = var.environment
  }
}
