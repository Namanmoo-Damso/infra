# EC2 Instance with EIP 모듈

EC2 인스턴스와 Elastic IP를 함께 생성하는 재사용 가능한 Terraform 모듈입니다.

## 기능

- EC2 인스턴스 생성 (여러 개 가능)
- Elastic IP 자동 할당
- GP3 볼륨 사용 (성능 최적화)
- User data 스크립트 지원 (선택사항)

## 사용 예시

### 기본 사용

```hcl
module "dev_servers" {
  source = "../../modules/compute/ec2-with-eip"

  instance_count    = 5
  ami_id            = "ami-0c447e8442d5380a3"
  instance_type     = "t3.medium"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_server.id
  tag_name          = "general-dev-server"
}
```

### User Data 포함

```hcl
module "dev_servers" {
  source = "../../modules/compute/ec2-with-eip"

  instance_count    = 5
  ami_id            = "ami-0c447e8442d5380a3"
  instance_type     = "t3.medium"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_server.id
  tag_name          = "general-dev-server"

  user_data = file("${path.module}/user-data/init.sh")
}
```

## 입력 변수

| 변수 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `instance_count` | number | ✅ | - | 생성할 인스턴스 개수 |
| `ami_id` | string | ✅ | - | 사용할 AMI ID |
| `instance_type` | string | ✅ | - | 인스턴스 타입 |
| `key_name` | string | ✅ | - | SSH 키 이름 |
| `security_group_id` | string | ✅ | - | 보안 그룹 ID |
| `tag_name` | string | ✅ | - | 인스턴스 Name 태그 |
| `volume_size` | number | ✅ | - | 루트 볼륨 크기 (GB) |
| `user_data` | string | ❌ | "" | 인스턴스 초기화 스크립트 |

## 출력값

| 출력 | 타입 | 설명 |
|------|------|------|
| `instance_ids` | list(string) | 생성된 인스턴스 ID 목록 |
| `public_ips` | list(string) | 할당된 Elastic IP 목록 |

## 출력값 사용 예시

```hcl
# 모듈 출력값 참조
output "server_ips" {
  value = module.dev_servers.public_ips
}
```
