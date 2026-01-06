data "aws_security_group" "example" {
  name = "general-dev-server"
}

module "dev-server" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-0c447e8442d5380a3"
  instance_count    = "5"
  instance_type     = "t3.medium"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.example.id
  tag_name          = "general_dev_server"
}

module "cpu_test" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-0c447e8442d5380a3"
  instance_count    = "5"
  instance_type     = "c7i.xlarge"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.example.id
  tag_name          = "c7i-xlarge-benchmark-server"
}

# AMI는 EC2 인스턴스의 템플릿으로, 다음을 포함해요:
# - OS: Linux (Amazon Linux, Ubuntu, CentOS 등), Windows 등. AMI 이름으로 OS를 선택해요 (예: "amzn2"는 Amazon Linux 2, "ubuntu"는 Ubuntu).
# - 애플리케이션/소프트웨어: 미리 설치된 패키지 (예: 웹 서버, 데이터베이스).
# - 설정: 루트 볼륨 크기, 네트워크 설정, 부트스트랩 스크립트 등.
# - 하드웨어 가상화: HVM (Hardware Virtual Machine)이나 PV (Paravirtual).



# - Selected AMI
#   ```json
#   {
#     "PlatformDetails": "Linux/UNIX",
#     "UsageOperation": "RunInstances",
#     "BlockDeviceMappings": [
#       {
#         "Ebs": {
#           "DeleteOnTermination": true,
#           "SnapshotId": "snap-03caf7c59107e3143",
#           "VolumeSize": 8,
#           "VolumeType": "gp3",
#           "Encrypted": false
#         },
#         "DeviceName": "/dev/sda1"
#       },
#       {
#         "DeviceName": "/dev/sdb",
#         "VirtualName": "ephemeral0"
#       },
#       {
#         "DeviceName": "/dev/sdc",
#         "VirtualName": "ephemeral1"
#       }
#     ],
#     "Description": "Canonical, Ubuntu Minimal, 24.04, amd64 noble image",
#     "EnaSupport": true,
#     "Hypervisor": "xen",
#     "ImageOwnerAlias": "amazon",
#     "Name": "ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-minimal-20251210",
#     "RootDeviceName": "/dev/sda1",
#     "RootDeviceType": "ebs",
#     "SriovNetSupport": "simple",
#     "VirtualizationType": "hvm",
#     "BootMode": "uefi-preferred",
#     "DeprecationTime": "2027-12-10T13:12:35.000Z",
#     "ImdsSupport": "v2.0",
#     "FreeTierEligible": true,
#     "ImageId": "ami-0c447e8442d5380a3",
#     "ImageLocation": "amazon/ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-minimal-20251210",
#     "State": "available",
#     "OwnerId": "099720109477",
#     "CreationDate": "2025-12-10T13:12:35.000Z",
#     "Public": true,
#     "Architecture": "x86_64",
#     "ImageType": "machine"
#   }
#   ```
