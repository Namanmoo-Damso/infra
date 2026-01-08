# =============================================================================
# 개발 환경 v1 - FE/BE 팀 범용 개발 서버
# =============================================================================

# -----------------------------------------------------------------------------
# 보안 그룹 참조 (global에서 생성된 것)
# -----------------------------------------------------------------------------
data "aws_security_group" "general_dev_server" {
  name = "general-dev-server"
}

# -----------------------------------------------------------------------------
# 범용 개발 서버 (FE/BE 팀용)
# -----------------------------------------------------------------------------
module "general_dev_servers" {
  source = "../../../modules/compute/ec2-with-eip"

  instance_count    = 5
  ami_id            = "ami-0c447e8442d5380a3" # Ubuntu 24.04 LTS
  instance_type     = "t3.medium"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "general-dev-server"

  user_data = file("${path.module}/user-data/init.sh")
}
