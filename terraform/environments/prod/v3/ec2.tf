# =============================================================================
# EC2 Instances
# =============================================================================

# -----------------------------------------------------------------------------
# Latest Ubuntu 24.04 LTS AMI (일반 서버용)
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# AWS Deep Learning AMI (GPU 서버용)
# -----------------------------------------------------------------------------
data "aws_ami" "deep_learning" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning OSS Nvidia Driver AMI GPU PyTorch * (Ubuntu 22.04) *"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# -----------------------------------------------------------------------------
# AI Agent Server (GPU)
# -----------------------------------------------------------------------------
resource "aws_instance" "ai_agent" {
  ami                    = data.aws_ami.deep_learning.id
  instance_type          = var.ai_agent_instance_type
  subnet_id              = aws_subnet.private_prod.id
  vpc_security_group_ids = [aws_security_group.ai_agent.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name

  root_block_device {
    volume_size           = 200
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = file("${path.module}/user-data/ai-agent-init.sh")

  tags = {
    Name        = "${var.project_name}-${var.environment}-ai-agent"
    Environment = var.environment
    Role        = "AI-Agent"
  }
}

# -----------------------------------------------------------------------------
# API Server
# -----------------------------------------------------------------------------
resource "aws_instance" "api_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.api_instance_type
  subnet_id              = aws_subnet.private_prod.id
  vpc_security_group_ids = [aws_security_group.api_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = file("${path.module}/user-data/api-server-init.sh")

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-server"
    Environment = var.environment
    Role        = "API"
  }
}

# -----------------------------------------------------------------------------
# Web Server
# -----------------------------------------------------------------------------
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.web_instance_type
  subnet_id              = aws_subnet.private_prod.id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = file("${path.module}/user-data/web-server-init.sh")

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-server"
    Environment = var.environment
    Role        = "Web"
  }
}
