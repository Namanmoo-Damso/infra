data "aws_security_group" "example" {
  name = "general-dev-server"
}

resource "aws_instance" "example" {
  count         = 3                       # 3개의 인스턴스 생성
  ami           = "ami-0c447e8442d5380a3" # 아래 소개
  instance_type = "t3.medium"

  # SSH 접속용 키 페어 (AWS 콘솔 > EC2 > Key Pairs에서 생성)
  key_name = "dev-server" # 실제 키 페어 이름으로 변경

  # 보안 그룹 (SSH 22번 포트 허용 등)
  vpc_security_group_ids = [data.aws_security_group.example.id] # 실제 보안 그룹 ID로 변경 (기본 VPC의 기본 SG 사용 가능)

  # 태그 (동적 이름 생성)
  tags = {
    Name        = "MyExampleInstance-${count.index}"
    Description = "test-dev-server"
  }

  # 루트 볼륨 크기 늘리기 (기본 8GB → 20GB)
  root_block_device {
    volume_size = 20    # GB 단위
    volume_type = "gp3" # SSD 타입
  }
}

# Elastic IP (고정 IP) 생성 및 할당
resource "aws_eip" "example" {
  count    = 3 # 인스턴스 수만큼
  instance = aws_instance.example[count.index].id
  tags = {
    Name = "EIP-for-Test-Instance-${count.index}"
  }
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
