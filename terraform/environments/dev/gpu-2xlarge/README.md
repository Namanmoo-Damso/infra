# 테스트 환경 v2

AI GPU 개발 서버 환경입니다.

## 리소스 구성

### 서버

| 이름 | 개수 | 타입 | GPU | 용도 |
|------|------|------|-----|------|
| ai-gpu-dev-server | 2개 | g5.xlarge | NVIDIA A10G 24GB | AI 모델 개발/테스트 |

## 인스턴스 사양

- **GPU**: NVIDIA A10G (24GB VRAM)
- **vCPU**: 4
- **메모리**: 16GB RAM
- **AMI**: Deep Learning Base GPU AMI (Ubuntu 24.04)
- **스토리지**: 200GB GP3
- **보안 그룹**: ai-gpu-server (SSH, HTTP, HTTPS)

## 사용 방법

### 1. 사전 준비

```bash
cd ../../global
terraform init
terraform apply  # 보안 그룹 생성
```

### 2. 초기화

```bash
cd terraform/environments/test/v2
terraform init
```

### 3. 배포

```bash
terraform plan
terraform apply
```

### 4. 서버 IP 확인

```bash
terraform output ai_gpu_dev_public_ips
```

### 5. SSH 접속

```bash
ssh -i ~/.ssh/dev-server.pem ubuntu@<PUBLIC_IP>
```

### 6. GPU 확인

```bash
# NVIDIA 드라이버 확인
nvidia-smi

# CUDA 버전 확인
nvcc --version
```

## 리소스 삭제

```bash
terraform destroy
```

## 주의사항

⚠️ **User Data 미설정**
- 현재 user_data 초기화 스크립트가 비어있습니다
- AI 환경 구성은 실제 사용하며 논의 후 추가 예정
- 필요한 패키지는 SSH 접속 후 수동 설치 필요

### GPU 인스턴스 특징
- g5.xlarge는 시간당 비용이 높으므로 사용 후 즉시 종료 권장
- Deep Learning AMI에는 NVIDIA 드라이버, CUDA가 사전 설치됨
- PyTorch, TensorFlow 등 주요 프레임워크 포함
