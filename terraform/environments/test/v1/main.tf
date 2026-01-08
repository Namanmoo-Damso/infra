# =============================================================================
# 테스트 환경 v1 - 인스턴스 타입 성능 테스트
# =============================================================================

# -----------------------------------------------------------------------------
# 보안 그룹 참조 (global에서 생성된 것)
# -----------------------------------------------------------------------------
data "aws_security_group" "general_dev_server" {
  name = "general-dev-server"
}

# -----------------------------------------------------------------------------
# c7i 테스트 서버 (Intel 7세대)
# -----------------------------------------------------------------------------
module "c7i_test" {
  source = "../../../modules/compute/ec2-with-eip"

  instance_count    = 1
  ami_id            = "ami-0c447e8442d5380a3" # Ubuntu 24.04 LTS (x86)
  instance_type     = "c7i.xlarge"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "c7i-xlarge-test"

  user_data = file("${path.module}/user-data/init.sh")
}

# -----------------------------------------------------------------------------
# Graviton4 테스트 서버 (AWS ARM 최신 세대)
# -----------------------------------------------------------------------------
module "graviton4_test" {
  source = "../../../modules/compute/ec2-with-eip"

  instance_count    = 1
  ami_id            = "ami-04f06fb5ae9dcc778" # Ubuntu 24.04 LTS ARM64 (for Graviton)
  instance_type     = "c8g.xlarge"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "c8g-xlarge-graviton4-test"

  user_data = file("${path.module}/user-data/init.sh")
}
