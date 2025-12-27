#!/bin/bash

# 에러 발생 시 중단하지 않고 체크만 하거나, set -e로 중단할지 결정 (여기선 유연하게 진행)

echo "🛠️ [Setup] Checking system dependencies..."

# 1. 패키지 리스트 업데이트
sudo apt-get update -y > /dev/null 2>&1

# 2. Git 설치 확인
if ! command -v git &> /dev/null; then
    echo "📦 Git not found. Installing Git..."
    sudo apt-get update -y && sudo apt-get install -y git
else
    echo "✅ Git is already installed."
fi

# 3. Docker 설치 확인 (예시)
if ! command -v docker &> /dev/null; then
    echo "📦 Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
else
    echo "✅ Docker is already installed."
fi

rm get-docker.sh

echo "🎉 [Setup] System provisioning complete."
