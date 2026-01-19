# =============================================================================
# Python Bot Server - ops-bot 프로젝트용
# =============================================================================

# -----------------------------------------------------------------------------
# 보안 그룹 참조 (global에서 생성된 것)
# -----------------------------------------------------------------------------
data "aws_security_group" "general_dev_server" {
  name = "general-dev-server"
}

# -----------------------------------------------------------------------------
# Python Bot 서버
# =============================================================================
# ops-bot Python 프로젝트 배포용 인스턴스
# SSH(22), HTTP(80), HTTPS(443) 포트 사용
# rsync, docker, git, gh 사전 설치
# -----------------------------------------------------------------------------
module "python_bot_server" {
  source = "../../../modules/compute/ec2-instance"

  instance_count      = 1
  ami_id              = "ami-0c447e8442d5380a3" # Ubuntu 24.04 LTS
  instance_type       = "m7i.2xlarge"           # 8 vCPU, 32GB RAM
  volume_size         = 100
  key_name            = "dev-server"
  security_group_id   = data.aws_security_group.general_dev_server.id
  availability_zone   = "ap-northeast-2d"
  tag_name            = "python-bot-server"

  user_data = templatefile("${path.module}/user-data/python-bot-init.sh.tftpl", {})
}
