# 테스트 환경 v1

인스턴스 타입 성능 비교 및 테스트 환경입니다.

## 리소스 구성

### 서버

| 이름 | 개수 | 타입 | 아키텍처 | 용도 |
|------|------|------|----------|------|
| c7i-xlarge-test | 1개 | c7i.xlarge | x86 (Intel) | Intel 7세대 성능 테스트 |
| c8g-xlarge-graviton4-test | 1개 | c8g.xlarge | ARM64 (Graviton4) | AWS Graviton4 성능 테스트 |

## 인스턴스 사양

### c7i.xlarge (Intel)
- **프로세서**: Intel Xeon (7세대)
- **vCPU**: 4 / **메모리**: 8GB
- **AMI**: Ubuntu 24.04 LTS (x86)
- **스토리지**: 20GB GP3

### c8g.xlarge (Graviton4)
- **프로세서**: AWS Graviton4 (ARM64)
- **vCPU**: 4 / **메모리**: 8GB
- **AMI**: Ubuntu 24.04 LTS ARM64
- **스토리지**: 20GB GP3
- **특징**: ARM 아키텍처 - 소프트웨어 호환성 확인 필요

## 사용 방법

### 1. 사전 준비

```bash
cd ../../global
terraform init
terraform apply  # 보안 그룹 생성
```

### 2. 초기화

```bash
cd terraform/environments/test/v1
terraform init
```

### 3. 개별 모듈 테스트 (선택적 실행)

#### c7i 테스트만 실행
```bash
terraform plan -target=module.c7i_test
terraform apply -target=module.c7i_test
```

#### Graviton4 테스트만 실행
```bash
terraform plan -target=module.graviton4_test
terraform apply -target=module.graviton4_test
```

#### 전체 실행
```bash
terraform apply
```

### 4. 서버 IP 확인

```bash
terraform output c7i_test_public_ips
terraform output graviton4_test_public_ips
```

### 5. SSH 접속

```bash
ssh -i ~/.ssh/dev-server.pem ubuntu@<PUBLIC_IP>

# 초기화 로그 확인
cat ~/initialization.log
```

### 6. 개별 리소스 삭제

#### c7i만 삭제
```bash
terraform destroy -target=module.c7i_test
```

#### Graviton4만 삭제
```bash
terraform destroy -target=module.graviton4_test
```

#### 전체 삭제
```bash
terraform destroy
```

## 성능 테스트 예시

### CPU 벤치마크
```bash
sudo apt-get install -y sysbench
sysbench cpu --threads=4 run
```

### 아키텍처 확인
```bash
uname -m  # x86_64 또는 aarch64
lscpu
```

### Docker ARM 호환성
Graviton4 (ARM)에서는 ARM64 이미지 필요:
```bash
docker run --platform linux/arm64 ubuntu:24.04
```

## 주의사항

- 테스트 목적이므로 필요한 서버만 선택적으로 실행 권장
- Graviton4는 ARM 아키텍처 - x86 전용 소프트웨어 호환성 주의
- user_data 초기화 완료까지 약 5분 소요
