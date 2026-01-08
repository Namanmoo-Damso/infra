# EC2 Instance 모듈 (EIP 없음)

Public IP를 사용하는 EC2 인스턴스를 생성하는 모듈입니다.

## 특징

- EC2 인스턴스 생성 (여러 개 가능)
- Public IP 자동 할당 (EIP 사용 안 함)
- GP3 볼륨 사용
- User data 스크립트 지원 (선택사항)
- IAM 인스턴스 프로파일 지원 (선택사항)

## ⚠️ 주의사항

**Public IP는 인스턴스 중지 후 재시작 시 변경됩니다!**

- 인스턴스를 **중지(Stop)하지 않고 삭제(Terminate)만** 할 경우 사용
- 또는 Route53로 도메인을 연결하여 IP 변경 시 자동 업데이트

## 사용 예시

### 기본 사용

```hcl
module "prod_server" {
  source = "../../modules/compute/ec2-instance"

  instance_count    = 1
  ami_id            = "ami-0c447e8442d5380a3"
  instance_type     = "c7i.xlarge"
  volume_size       = 50
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "prod-server"
}
```

### IAM Role과 함께 사용

```hcl
module "prod_server" {
  source = "../../modules/compute/ec2-instance"

  instance_count       = 1
  ami_id               = "ami-0c447e8442d5380a3"
  instance_type        = "c7i.xlarge"
  volume_size          = 50
  key_name             = "dev-server"
  security_group_id    = data.aws_security_group.general_dev_server.id
  tag_name             = "prod-server"
  iam_instance_profile = aws_iam_instance_profile.prod_ec2.name
  user_data            = file("${path.module}/user-data/init.sh")
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
| `iam_instance_profile` | string | ❌ | "" | IAM 인스턴스 프로파일 이름 |

## 출력값

| 출력 | 타입 | 설명 |
|------|------|------|
| `instance_ids` | list(string) | 생성된 인스턴스 ID 목록 |
| `public_ips` | list(string) | Public IP 목록 |
| `private_ips` | list(string) | Private IP 목록 |

## ec2-with-eip 모듈과의 차이

| 항목 | ec2-instance | ec2-with-eip |
|------|--------------|--------------|
| IP 타입 | Public IP | Elastic IP |
| IP 고정성 | ❌ 재시작 시 변경 | ✅ 영구 고정 |
| EIP 쿼타 소비 | ❌ 없음 | ✅ 있음 |
| 사용 사례 | 배포 서버 (1대) | 개발 서버 (여러 대) |
