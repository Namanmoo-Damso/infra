# =============================================================================
# 개발 환경 v2 - LiveKit 전용 서버
# =============================================================================

# -----------------------------------------------------------------------------
# 보안 그룹 참조 (global에서 생성된 것)
# -----------------------------------------------------------------------------
data "aws_security_group" "general_dev_server" {
  name = "general-dev-server"
}

# -----------------------------------------------------------------------------
# LiveKit 전용 서버
# =============================================================================
# 개발자들이 공유하는 단일 LiveKit 인스턴스
# WebRTC 미디어 서버로 독립 운영
# c7i 인스턴스: CPU 집약적인 WebRTC 미디어 처리에 최적화
# -----------------------------------------------------------------------------
module "livekit_server" {
  source = "../../../modules/compute/ec2-instance"

  instance_count    = 1
  ami_id            = "ami-0c447e8442d5380a3" # Ubuntu 24.04 LTS
  instance_type     = "c7i.xlarge"            # 4 vCPU, 8GB RAM (WebRTC 최적화)
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "livekit-dev-server"

  user_data = templatefile("${path.module}/user-data/livekit-init.sh.tftpl", {
    webhook_urls       = join(" ", var.api_webhook_urls)
    livekit_api_key    = var.livekit_api_key
    livekit_api_secret = var.livekit_api_secret
  })
}
