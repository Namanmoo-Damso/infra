# v3 프로덕션 배포 가이드

3개 EC2 인스턴스에 Docker Compose로 서비스를 배포하는 가이드입니다.

## 사전 준비

### 1. 이미지 빌드 및 GHCR 푸시

로컬 머신에서:
```bash
cd deployment-artifacts/build
./build-and-push.sh
```

### 2. 각 EC2에 파일 전송

이미 완료했다고 가정합니다:
- API EC2: `api-server/` 디렉토리 (docker-compose.yml, api.env, deploy.sh)
- Web EC2: `web-server/` 디렉토리 (docker-compose.yml, web.env, deploy.sh)
- Agent EC2: `ai-agent/` 디렉토리 (docker-compose.yml, agent.env, deploy.sh)

### 3. GHCR 인증 (Optional, Private 이미지인 경우만)

각 EC2에서 환경변수 설정:
```bash
export GHCR_USERNAME=<your-github-username>
export GHCR_TOKEN=<your-github-pat>
```

영구 설정 (권장):
```bash
echo 'export GHCR_USERNAME=<your-github-username>' >> ~/.bashrc
echo 'export GHCR_TOKEN=<your-github-pat>' >> ~/.bashrc
source ~/.bashrc
```

## 배포 순서 (중요!)

배포는 **반드시 이 순서**대로 진행해야 합니다:

### 1단계: API 서버 배포 (먼저)

AI Agent가 API 서버에 의존하므로 API를 먼저 배포해야 합니다.

**API EC2 (i-0ea60c659c1c07d67, 10.0.10.8)**에 접속:
```bash
# SSM으로 접속
aws ssm start-session --target i-0ea60c659c1c07d67

# 또는 SSH
ssh -i ~/.ssh/your-key.pem ubuntu@<api-ec2-ip>
```

배포 실행:
```bash
cd /path/to/api-server
./deploy.sh
```

**예상 시간**: 2-3분

**검증**:
```bash
# Health check
curl http://localhost:8080/health

# 로그 확인
docker compose logs -f api
```

### 2단계: Web 서버 배포

**Web EC2 (i-03b64e1caa4515d3f, 10.0.10.246)**에 접속:
```bash
# SSM으로 접속
aws ssm start-session --target i-03b64e1caa4515d3f

# 또는 SSH
ssh -i ~/.ssh/your-key.pem ubuntu@<web-ec2-ip>
```

배포 실행:
```bash
cd /path/to/web-server
./deploy.sh
```

**예상 시간**: 2-3분

**검증**:
```bash
# Health check
curl http://localhost:3000/

# 로그 확인
docker compose logs -f web
```

### 3단계: AI Agent 배포 (마지막)

API 서버가 정상 동작하는지 확인한 후 진행합니다.

**Agent EC2 (i-0b5235e6fd6101ed6, 10.0.10.114)**에 접속:
```bash
# SSM으로 접속
aws ssm start-session --target i-0b5235e6fd6101ed6

# 또는 SSH
ssh -i ~/.ssh/your-key.pem ubuntu@<agent-ec2-ip>
```

배포 실행:
```bash
cd /path/to/ai-agent
./deploy.sh
```

**예상 시간**: 15-20분 (이미지 다운로드 5-10분 + 모델 로딩 2-3분)

**검증**:
```bash
# 서비스 상태
docker compose ps

# GPU 사용 확인
nvidia-smi

# 각 서비스 health check
curl http://localhost:8000/health      # STT
curl http://localhost:11434/api/tags   # Ollama
curl http://localhost:8001/sse         # MCP

# 로그 확인
docker compose logs -f agent
docker compose logs -f ollama
docker compose logs -f stt
```

## 배포 스크립트가 하는 일

각 `deploy.sh` 스크립트는 다음 작업을 수행합니다:

1. **환경 확인**: Docker, Docker Compose 설치 여부
2. **GHCR 로그인**: 환경변수가 있으면 로그인 시도
3. **이미지 pull**: GHCR에서 최신 v3 이미지 다운로드
4. **기존 컨테이너 중지**: 이미 실행 중인 컨테이너가 있으면 중지
5. **컨테이너 시작**: `docker compose up -d`로 데몬 모드 실행
6. **Health check 대기**: 서비스가 healthy 상태가 될 때까지 대기
7. **상태 출력**: 컨테이너 상태 및 로그 표시

## 트러블슈팅

### GHCR 이미지 pull 실패

```
Error response from daemon: unauthorized
```

**해결**:
1. 이미지가 private인지 확인
2. GHCR_USERNAME/GHCR_TOKEN 환경변수 설정
3. 다시 deploy.sh 실행

### Health check 타임아웃

```
Health check timeout reached
```

**원인**:
- 네트워크 지연
- 모델 로딩 시간 초과 (AI Agent)
- 서비스 시작 실패

**해결**:
```bash
# 로그 확인
docker compose logs [service-name]

# 특정 서비스 재시작
docker compose restart [service-name]

# 전체 재시작
docker compose down && docker compose up -d
```

### GPU not available (AI Agent)

```
nvidia-smi is not available
```

**해결**:
1. GPU 드라이버 설치 확인: `nvidia-smi`
2. NVIDIA Container Toolkit 설치 확인
3. Docker daemon 재시작: `sudo systemctl restart docker`

### AI Agent가 API 서버 연결 실패

```
Connection refused to http://10.0.10.8:8080
```

**원인**: API 서버가 먼저 실행되지 않음

**해결**:
1. API EC2에서 API 서버 상태 확인: `docker compose ps`
2. API 서버 health check: `curl http://localhost:8080/health`
3. 보안그룹 확인: Agent EC2가 API EC2의 8080 포트 접근 가능한지

## 유용한 명령어

### 로그 확인
```bash
# 실시간 로그 (모든 서비스)
docker compose logs -f

# 특정 서비스만
docker compose logs -f [service-name]

# 최근 100줄
docker compose logs --tail=100
```

### 서비스 재시작
```bash
# 특정 서비스
docker compose restart [service-name]

# 전체 재시작
docker compose restart
```

### 서비스 중지
```bash
# 중지 (컨테이너 유지)
docker compose stop

# 완전 제거 (컨테이너 삭제)
docker compose down

# 볼륨까지 제거 (주의!)
docker compose down -v
```

### 상태 확인
```bash
# 컨테이너 상태
docker compose ps

# 리소스 사용량
docker stats

# GPU 사용량 (AI Agent)
nvidia-smi
```

### 이미지 업데이트
```bash
# 최신 이미지 pull
docker compose pull

# 재시작
docker compose up -d
```

## 롤백

문제 발생 시 이전 버전으로 롤백:

1. **이미지 태그 변경**: `docker-compose.yml`에서 `v3` → `v2` (또는 이전 태그)
2. **재배포**: `./deploy.sh` 실행

또는 수동으로:
```bash
docker compose down
# docker-compose.yml 수정
docker compose pull
docker compose up -d
```

## 모니터링

배포 후 다음 사항을 모니터링하세요:

### API 서버
- Health endpoint: `http://10.0.10.8:8080/health`
- Logs: 에러 로그 확인
- Database 연결: RDS 접근 가능 여부

### Web 서버
- Health endpoint: `http://10.0.10.246:3000/`
- Next.js 빌드 에러 확인

### AI Agent
- GPU 메모리 사용량: `nvidia-smi` (최대 16GB)
- Livekit 연결 상태
- API 서버 연결 상태
- 모델 로딩 상태 (ollama, whisper)

## 다음 단계

배포 완료 후:

1. **ALB Health Check**: ALB 타겟 그룹에서 API/Web 인스턴스 healthy 확인
2. **Route53 설정**: api.sodam.store, sodam.store 도메인 매핑
3. **통합 테스트**: 실제 화상통화 테스트
4. **모니터링 설정**: CloudWatch 알람 구성
