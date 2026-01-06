data "aws_security_group" "general_dev_server" {
  name = "general-dev-server"
}

module "dev-server" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-0c447e8442d5380a3"
  instance_count    = 5
  instance_type     = "t3.medium"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "general_dev_server"
}

module "cpu_test" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-0c447e8442d5380a3"
  instance_count    = 1
  instance_type     = "c7i.xlarge"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "c7i-xlarge-benchmark-server"
}

# C8g.xlarge (AWS Graviton4) 벤치마크 서버
# - 목적: C7i(Intel) 대비 Graviton4(ARM) 성능 비교
# - 프로세서: AWS Graviton4 (ARM64, 최신 세대)
# - 예상 성능: C7g 대비 30% 향상, C7i 대비 우수한 가격 대비 성능
# - 주의: ARM 아키텍처이므로 소프트웨어 호환성 확인 필요
module "graviton4_test" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-04f06fb5ae9dcc778" # Ubuntu 24.04 ARM64 (for Graviton)
  instance_count    = 1
  instance_type     = "c8g.xlarge" # AWS Graviton4 (ARM64, 4 vCPU, 8GB RAM)
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "c8g-xlarge-graviton4-benchmark"
}
