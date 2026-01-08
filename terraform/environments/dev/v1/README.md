# 개발 환경 v1

FE/BE 팀을 위한 범용 개발 서버 환경입니다.

## 리소스 구성

### 서버

| 이름 | 개수 | 타입 | 용도 |
|------|------|------|------|
| general-dev-server | 5개 | t3.medium | FE/BE 팀 일반 개발 |

### 인스턴스 사양

- **AMI**: Ubuntu 24.04 LTS (ami-0c447e8442d5380a3)
- **인스턴스 타입**: t3.medium (2 vCPU, 4GB RAM)
- **스토리지**: 20GB GP3
- **네트워크**: Elastic IP 자동 할당
- **보안 그룹**: general-dev-server
  - SSH (22)
  - HTTP (80), HTTPS (443)
  - LiveKit (7880, 7881, 50000-60000/udp)

## 사용 방법

### 1. 사전 준비

global 환경의 보안 그룹이 생성되어 있어야 합니다:

```bash
cd ../../global
terraform init
terraform apply
```

### 2. 리소스 생성

```bash
cd terraform/environments/dev/v1
terraform init
### 3. 배포 계획 확인
terraform plan
### 4. 배포 실행
terraform apply
### 5. 서버 IP 확인
terraform output general_dev_server_public_ips
### 6. SSH 접속
ssh -i ~/.ssh/dev-server.pem ubuntu@<PUBLIC_IP>
```

### 3. 리소스 삭제

```bash
terraform destroy
```

## 주의사항

- SSH 키 `dev-server`가 AWS에 등록되어 있어야 합니다
- 실제 키 파일은 `secrets/ssh-keys/dev-server.pem`에 있습니다
- terraform.tfstate 파일은 로컬에서 관리됩니다
