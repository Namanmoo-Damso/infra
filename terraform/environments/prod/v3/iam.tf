# =============================================================================
# IAM Roles and Policies
# =============================================================================

# -----------------------------------------------------------------------------
# EC2 Instance Role (SSM 접근용)
# -----------------------------------------------------------------------------

# IAM Role
resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

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

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Environment = var.environment
  }
}

# SSM 관리 정책 연결 (Systems Manager 접근용)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent 정책 연결 (로그 및 메트릭 수집)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# S3 접근 정책 (환경변수 파일 다운로드용)
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.project_name}-${var.environment}-s3-access-policy"
  role = aws_iam_role.ec2_instance_role.id

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
          "arn:aws:s3:::${var.project_name}-deployment/*",
          "arn:aws:s3:::${var.project_name}-deployment"
        ]
      }
    ]
  })
}

# ECR 접근 정책 (Docker 이미지 pull용)
resource "aws_iam_role_policy" "ecr_access" {
  name = "${var.project_name}-${var.environment}-ecr-access-policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance Profile (EC2에 Role 연결용)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-profile"
    Environment = var.environment
  }
}
