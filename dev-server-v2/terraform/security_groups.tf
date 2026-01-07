# data 키워드는 이미 만들어 둔 것을 참조만 함
data "aws_security_group" "general_dev_server" {
  name = "general-dev-server"
}

# AI GPU 서버용 보안 그룹
resource "aws_security_group" "ai_gpu_server" {
  name        = "ai-gpu-server"
  description = "Security group for AI GPU servers communicating LiveKit (STT/LLM/TTS)"

  # SSH
  ingress {
    description = "SSH access"
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

  # WebRTC Media (UDP)
  # LiveKit이 실시간 음성/영상 스트리밍에 사용
  ingress {
    description = "WebRTC Media Ports"
    from_port   = 50000
    to_port     = 60000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ai-gpu-server"
    Description = "AI GPU servers for LiveKit real-time voice/video agents"
    ManagedBy   = "Terraform"
  }
}
