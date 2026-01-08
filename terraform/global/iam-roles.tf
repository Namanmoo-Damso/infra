# =============================================================================
# IAM Role - EC2가 S3에 접근하기 위한 권한
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role 생성
# -----------------------------------------------------------------------------
resource "aws_iam_role" "prod_ec2_s3_access" {
  name = "prod-ec2-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name      = "prod-ec2-s3-access"
    ManagedBy = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy - S3 버킷 접근 권한 정의
# ref: https://github.com/Namanmoo-Damso/infra/issues/18
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "prod_s3_access" {
  name = "prod-s3-access"
  role = aws_iam_role.prod_ec2_s3_access.id

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
          "arn:aws:s3:::sodam-prod-artifacts",
          "arn:aws:s3:::sodam-prod-artifacts/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM Instance Profile - EC2에 연결하기 위한 프로파일
# -----------------------------------------------------------------------------
resource "aws_iam_instance_profile" "prod_ec2" {
  name = "prod-ec2-profile"
  role = aws_iam_role.prod_ec2_s3_access.name

  tags = {
    Name      = "prod-ec2-profile"
    ManagedBy = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "prod_ec2_instance_profile_name" {
  description = "배포 서버용 IAM 인스턴스 프로파일 이름"
  value       = aws_iam_instance_profile.prod_ec2.name
}

output "prod_ec2_iam_role_arn" {
  description = "배포 서버용 IAM Role ARN"
  value       = aws_iam_role.prod_ec2_s3_access.arn
}
