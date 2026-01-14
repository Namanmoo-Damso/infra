# 배포 가이드

## 1. 개발 머신에서 이미지 빌드 & Push

```bash
# GHCR 로그인
export GITHUB_USERNAME=your-username
export GITHUB_TOKEN=your-github-token

# 기본 사용 (main 브랜치 최신)
./build-and-push.sh

# 특정 커밋 해시 지정
GIT_REF=abc1234 ./build-and-push.sh

# 특정 브랜치 지정
GIT_REF=develop ./build-and-push.sh

# 특정 태그 지정
GIT_REF=v1.0.0 ./build-and-push.sh
```

**참고**: 스크립트는 자동으로 GitHub에서 저장소를 clone하고 지정된 git reference로 checkout합니다.

## 2. 배포 인스턴스 설정

```bash
# 필요한 파일만 복사
ops-api/
├── docker-compose.staging.yml
├── api.staging.env
├── db.env
├── Caddyfile
├── init-db.sql
└── secrets/

ops-agent/
├── docker-compose.staging.yml
└── agent.staging.env
```

## 3. 실행

```bash
# ops-api 실행
cd ops-api
docker-compose -f docker-compose.staging.yml pull
docker-compose -f docker-compose.staging.yml up -d

# ops-agent 실행
cd ops-agent
docker-compose -f docker-compose.staging.yml pull
docker-compose -f docker-compose.staging.yml up -d
```
