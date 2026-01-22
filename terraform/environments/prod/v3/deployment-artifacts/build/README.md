# v3 이미지 빌드 시스템

v3 프로덕션 배포를 위한 Docker 이미지 빌드 및 GHCR 푸시 시스템입니다.

## 개요

### 빌드 대상 이미지 (총 7개)

1. `ghcr.io/namanmoo-damso/ops-api:v3` - NestJS API 서버
2. `ghcr.io/namanmoo-damso/ops-web:v3` - Next.js 웹 서버
3. `ghcr.io/namanmoo-damso/ops-agent-stt:v3` - Whisper STT (GPU)
4. `ghcr.io/namanmoo-damso/ops-agent-ollama:v3` - Ollama LLM (GPU)
5. `ghcr.io/namanmoo-damso/ops-agent:v3` - AI Agent 메인
6. `ghcr.io/namanmoo-damso/ops-agent-transcript:v3` - 대화 저장 워커
7. `ghcr.io/namanmoo-damso/ops-agent-kma-mcp:v3` - 기상청 MCP 서버

### 빌드 전략

- **중앙집중식**: 단일 `docker-compose.build.yml`로 모든 이미지 관리
- **고정 태그**: 모든 이미지를 `v3` 태그로 통일
- **AMD64 타겟**: EC2 인스턴스 아키텍처에 맞춰 `linux/amd64`만 빌드
- **태그 기반 clone**: GitHub에서 `v3` 태그를 기준으로 소스코드 clone

## 사전 준비

### 1. GitHub 레포지토리에 v3 태그 생성

각 레포지토리에서 배포할 커밋에 `v3` 태그를 생성하세요:

```bash
# ops-api 레포
cd /path/to/ops-api
git tag -a v3 -m "Production v3 release"
git push origin v3

# ops-web 레포
cd /path/to/ops-web
git tag -a v3 -m "Production v3 release"
git push origin v3

# ops-agent 레포
cd /path/to/ops-agent
git tag -a v3 -m "Production v3 release"
git push origin v3
```

### 2. GHCR 인증 정보 준비

GitHub Container Registry에 푸시하려면 GitHub Personal Access Token이 필요합니다.

**Token 생성 방법**:
1. GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. 권한 선택: `write:packages`, `read:packages`, `delete:packages`
4. Token 복사 및 안전하게 보관

**환경변수 설정**:
```bash
export GHCR_USERNAME=<your-github-username>
export GHCR_TOKEN=<your-github-pat>
```

## 빌드 및 푸시

### 자동 빌드 (권장)

```bash
cd deployment-artifacts/build
./build-and-push.sh
```

**스크립트 동작**:
1. `repos/` 디렉토리 초기화
2. GitHub에서 `v3` 태그로 3개 레포지토리 clone
3. GHCR 로그인 확인
4. 모든 이미지 빌드 (10-30분 소요)
5. GHCR에 이미지 푸시

### 수동 빌드 (디버깅용)

#### 1단계: 레포지토리 clone

```bash
cd deployment-artifacts/build
rm -rf repos/
mkdir -p repos/

git clone --branch v3 --depth 1 https://github.com/Namanmoo-Damso/ops-api.git repos/ops-api
git clone --branch v3 --depth 1 https://github.com/Namanmoo-Damso/ops-web.git repos/ops-web
git clone --branch v3 --depth 1 https://github.com/Namanmoo-Damso/ops-agent.git repos/ops-agent
```

#### 2단계: GHCR 로그인

```bash
echo $GHCR_TOKEN | docker login ghcr.io -u $GHCR_USERNAME --password-stdin
```

#### 3단계: 이미지 빌드

```bash
# 전체 빌드
docker compose -f docker-compose.build.yml build

# 특정 이미지만 빌드 (예: API만)
docker compose -f docker-compose.build.yml build api
```

#### 4단계: GHCR 푸시

```bash
# 전체 푸시
docker compose -f docker-compose.build.yml push

# 특정 이미지만 푸시
docker compose -f docker-compose.build.yml push api
```

## 빌드 환경변수 커스터마이즈

Next.js 웹 서버는 빌드타임에 환경변수가 필요합니다. `docker-compose.build.yml`에서 수정 가능합니다:

```yaml
web:
  build:
    args:
      - NEXT_PUBLIC_API_BASE=https://api.sodam.store
      - NEXT_PUBLIC_ROOM_NAME=sodam-v3
      - NEXT_PUBLIC_NAVER_MAP_CLIENT_ID=<your-id>
      - NEXT_PUBLIC_KAKAO_CLIENT_ID=<your-id>
      - NEXT_PUBLIC_GOOGLE_CLIENT_ID=<your-id>
```

## 빌드 결과 확인

### 로컬에서 이미지 확인

```bash
docker images | grep namanmoo-damso
```

### GHCR에서 이미지 확인

1. GitHub Organization 페이지 → Packages
2. 각 이미지의 `v3` 태그 확인

### 이미지 pull 테스트

```bash
docker pull ghcr.io/namanmoo-damso/ops-api:v3
docker pull ghcr.io/namanmoo-damso/ops-web:v3
docker pull ghcr.io/namanmoo-damso/ops-agent:v3
```

## 트러블슈팅

### 태그가 존재하지 않음 에러

```
Failed to clone ops-api with tag v3
```

**해결**: 각 레포지토리에 `v3` 태그를 먼저 생성하고 push하세요.

### GHCR 로그인 실패

```
Error response from daemon: Get "https://ghcr.io/v2/": unauthorized
```

**해결**:
- GHCR_TOKEN이 올바른지 확인
- Token 권한에 `write:packages`가 포함되어 있는지 확인

### 빌드 중 메모리 부족

**해결**: Docker Desktop 메모리 할당 증가 (Preferences → Resources → Memory)

### 크로스 플랫폼 빌드 경고

```
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform
```

**해결**: 정상입니다. EC2가 AMD64이므로 의도된 동작입니다.

## 디렉토리 구조

```
build/
├── repos/                          # git clone된 레포지토리들 (gitignore)
│   ├── ops-api/
│   ├── ops-web/
│   └── ops-agent/
├── docker-compose.build.yml        # 빌드 설정
├── build-and-push.sh               # 빌드 스크립트
└── README.md                       # 본 문서
```

## 다음 단계

이미지 빌드 및 푸시가 완료되면:

1. EC2 인스턴스 프로비저닝 (Terraform)
2. 배포 스크립트로 EC2에 이미지 배포
3. 서비스 헬스체크 및 검증

자세한 내용은 `../scripts/` 디렉토리의 배포 스크립트를 참고하세요.
