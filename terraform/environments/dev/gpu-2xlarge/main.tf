# =============================================================================
# 테스트 환경 v2 - AI GPU 개발 서버
# =============================================================================

# -----------------------------------------------------------------------------
# 보안 그룹 참조 (global에서 생성된 것)
# -----------------------------------------------------------------------------
data "aws_security_group" "ai_gpu_server" {
  name = "ai-gpu-server"
}

# -----------------------------------------------------------------------------
# AI GPU 개발 서버
# -----------------------------------------------------------------------------
module "ai_gpu_dev_servers" {
  source = "../../../modules/compute/ec2-instance"

  instance_count    = 5
  ami_id            = "ami-09399dbfdc84fada6" # Deep Learning Base GPU AMI (Ubuntu 24.04)
  instance_type     = "g5.2xlarge"            # NVIDIA A10G 24GB, 8 vCPU, 32GB RAM
  volume_size       = 200
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.ai_gpu_server.id
  tag_name          = "gpu-dev"
  start_stopped     = true
  # user_data는 비워둠 - 추후 AI 환경 구성 논의 후 추가 예정
}
