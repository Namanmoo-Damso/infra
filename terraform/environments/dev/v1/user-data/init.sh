#!/bin/bash
# =============================================================================
# 개발 서버 초기화 스크립트
# =============================================================================
# 인스턴스 시작 시 자동으로 실행되어 개발 환경을 구성합니다.
# 로그: /home/ubuntu/initialization.log
# =============================================================================

set -e

LOG_FILE="/home/ubuntu/initialization.log"

# 로그 함수
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

log_message "=========================================="
log_message "개발 서버 초기화 시작"
log_message "시작 시간: $(date)"
log_message "=========================================="
log_message ""

# -----------------------------------------------------------------------------
# 1. 시스템 업데이트 및 기본 패키지 설치
# -----------------------------------------------------------------------------
log_message "[1/7] 시스템 업데이트 및 기본 패키지 설치..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1
apt-get install -y \
    curl wget vim unzip jq htop rsync \
    build-essential ca-certificates gnupg lsb-release > /dev/null 2>&1
log_message "      ✅ 완료"

# -----------------------------------------------------------------------------
# 2. 시간대 설정
# -----------------------------------------------------------------------------
log_message "[2/7] 시간대 설정 (Asia/Seoul)..."
timedatectl set-timezone Asia/Seoul
log_message "      ✅ 완료"

# -----------------------------------------------------------------------------
# 3. Git 설치
# -----------------------------------------------------------------------------
log_message "[3/7] Git 설치..."
if ! command -v git &> /dev/null; then
    apt-get install -y git > /dev/null 2>&1
fi
GIT_VERSION=$(git --version)
log_message "      ✅ $GIT_VERSION"

# -----------------------------------------------------------------------------
# 4. GitHub CLI 설치
# -----------------------------------------------------------------------------
log_message "[4/7] GitHub CLI 설치..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                                                                             | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null 2>&1
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
                                                                                                                                                           | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt-get update -y > /dev/null 2>&1
    apt-get install -y gh > /dev/null 2>&1
fi
GH_VERSION=$(gh --version | head -n1)
log_message "      ✅ $GH_VERSION"

# -----------------------------------------------------------------------------
# 5. Docker 설치
# -----------------------------------------------------------------------------
log_message "[5/7] Docker 설치..."
if ! command -v docker &> /dev/null; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
                                                               | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y > /dev/null 2>&1
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
    systemctl start docker
    systemctl enable docker
fi
DOCKER_VERSION=$(docker --version)
log_message "      ✅ $DOCKER_VERSION"

# -----------------------------------------------------------------------------
# 6. Docker 권한 설정
# -----------------------------------------------------------------------------
log_message "[6/7] Docker 사용자 권한 설정..."
if ! groups ubuntu | grep -q docker; then
    usermod -aG docker ubuntu
fi
log_message "      ✅ ubuntu 사용자를 docker 그룹에 추가"

# -----------------------------------------------------------------------------
# 7. 정리
# -----------------------------------------------------------------------------
log_message "[7/7] 정리 작업..."
apt-get autoremove -y > /dev/null 2>&1
apt-get clean
log_message "      ✅ 완료"

log_message ""
log_message "=========================================="
log_message "✅ 개발 서버 초기화 완료"
log_message "완료 시간: $(date)"
log_message "=========================================="

# 권한 설정
chown ubuntu:ubuntu "$LOG_FILE"
touch /tmp/init-complete
