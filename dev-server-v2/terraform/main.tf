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
