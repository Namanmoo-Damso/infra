#!/bin/bash
# =============================================================================
# Production Server Initialization Script
# =============================================================================
# 1. Docker & Docker Compose 설치
# 2. AWS CLI 설치
# 3. S3에서 env.zip 다운로드
# 4. 압축 해제 및 docker-compose up
# =============================================================================

set -e

LOG_FILE="/home/ubuntu/initialization.log"
DEPLOY_DIR="/home/ubuntu/deploy"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "=== Production Server Initialization Started ==="

# -----------------------------------------------------------------------------
# 1. 시스템 업데이트
# -----------------------------------------------------------------------------
log_message "Updating system packages..."
apt-get update
apt-get upgrade -y

# -----------------------------------------------------------------------------
# 2. Docker 설치
# -----------------------------------------------------------------------------
log_message "Installing Docker..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
                                                           | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log_message "Docker installed successfully"
docker --version | tee -a "$LOG_FILE"
docker compose version | tee -a "$LOG_FILE"

# -----------------------------------------------------------------------------
# 3. ubuntu 사용자를 docker 그룹에 추가
# -----------------------------------------------------------------------------
log_message "Adding ubuntu user to docker group..."
usermod -aG docker ubuntu

# -----------------------------------------------------------------------------
# 4. AWS CLI 설치 (이미 설치되어 있을 수 있음)
# -----------------------------------------------------------------------------
if ! command -v aws &> /dev/null; then
    log_message "Installing AWS CLI..."
    apt-get install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    log_message "AWS CLI installed successfully"
else
    log_message "AWS CLI already installed"
fi
aws --version | tee -a "$LOG_FILE"

# -----------------------------------------------------------------------------
# 5. 배포 디렉토리 생성
# -----------------------------------------------------------------------------
log_message "Creating deployment directory..."
mkdir -p "$DEPLOY_DIR"
chown ubuntu:ubuntu "$DEPLOY_DIR"

# -----------------------------------------------------------------------------
# 6. S3에서 artifacts 다운로드
# -----------------------------------------------------------------------------
log_message "Downloading env.zip, docker-compose.yml from S3..."
cd "$DEPLOY_DIR"
aws s3 cp s3://sodam-prod-artifacts/prod/v1/ ./ --recursive
log_message "Downloaded env.zip, docker-compose.yml successfully"

# -----------------------------------------------------------------------------
# 7. 압축 해제
# -----------------------------------------------------------------------------
log_message "Extracting env.zip..."
unzip -o env.zip
rm env.zip
log_message "Extracted deployment artifacts"

# -----------------------------------------------------------------------------
# 8. secrets 디렉토리 생성 (레거시 호환성)
# -----------------------------------------------------------------------------
mkdir -p secrets
chown -R ubuntu:ubuntu "$DEPLOY_DIR"
log_message "Created secrets directory for legacy compatibility"

# -----------------------------------------------------------------------------
# 9. GitHub Container Registry 로그인 (public 이미지이므로 skip)
# -----------------------------------------------------------------------------
log_message "Pulling images from GHCR (public repository)..."
docker compose pull | tee -a "$LOG_FILE"

# -----------------------------------------------------------------------------
# 10. Docker Compose 실행
# -----------------------------------------------------------------------------
log_message "Starting services with docker-compose..."
docker compose up -d | tee -a "$LOG_FILE"

log_message "Waiting for services to be healthy..."
sleep 10
docker compose ps | tee -a "$LOG_FILE"

# -----------------------------------------------------------------------------
# 완료
# -----------------------------------------------------------------------------
log_message "=== Production Server Initialization Completed ==="
log_message "Services are running at /home/ubuntu/deploy"
log_message "Check status: cd $DEPLOY_DIR && docker compose ps"

touch /tmp/init-complete
chown ubuntu:ubuntu "$LOG_FILE"
