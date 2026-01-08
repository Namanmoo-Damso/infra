# =============================================================================
# 보안 그룹 정의
# =============================================================================
# 모든 환경에서 공유하는 보안 그룹을 중앙에서 관리
# =============================================================================

# -----------------------------------------------------------------------------
# 범용 개발 서버 보안 그룹 (FE/BE 팀 - LiveKit 서버 포함)
# -----------------------------------------------------------------------------
resource "aws_security_group" "general_dev_server" {
  name        = "general-dev-server"
  description = "General development server security group (includes LiveKit)"

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # LiveKit HTTP API
  ingress {
    description = "LiveKit HTTP API"
    from_port   = 7880
    to_port     = 7880
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # LiveKit WebSocket/Signaling
  ingress {
    description = "LiveKit WebSocket"
    from_port   = 7881
    to_port     = 7881
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # LiveKit TCP Fallback (방화벽 등으로 UDP 차단 시 대체)
  ingress {
    description = "LiveKit TCP Fallback"
    from_port   = 7883
    to_port     = 7883
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WebRTC Media (UDP) - 실시간 음성/영상 스트리밍
  ingress {
    description = "WebRTC Media"
    from_port   = 50000
    to_port     = 60000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 허용
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "general-dev-server"
    ManagedBy = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# AI GPU 서버 보안 그룹 (GPU 연산용)
# -----------------------------------------------------------------------------
resource "aws_security_group" "ai_gpu_server" {
  name        = "ai-gpu-server"
  description = "AI GPU server security group"

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 허용
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "ai-gpu-server"
    ManagedBy = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# Outputs - 다른 환경에서 참조
# -----------------------------------------------------------------------------
output "general_dev_server_sg_id" {
  description = "범용 개발 서버 보안 그룹 ID"
  value       = aws_security_group.general_dev_server.id
}

output "ai_gpu_server_sg_id" {
  description = "AI GPU 서버 보안 그룹 ID"
  value       = aws_security_group.ai_gpu_server.id
}
