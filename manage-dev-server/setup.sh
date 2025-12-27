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

if ! command -v gh &> /dev/null; then
    echo "📦 GH not found. Installing GH..."
    sudo apt-get update -y && sudo apt-get install -y gh
else
    echo "✅ GH is already installed."
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

# 4. github 사용을 위한 인증 절차
if gh auth status 2> /dev/null | grep -q "Logged in"; then
    echo "✅ Already logged in to GitHub."
else
    echo
    echo "github 사용을 위해 인증이 필요합니다."
    echo "아래와 같이 진행하여 인증 및 ssh 키 등록을 마칩니다."
    echo
    echo "ubuntu@ip-172-31-38-179:~$ gh auth login"
    echo
    echo "e.g."
    echo "? What account do you want to log into? GitHub.com"
    echo "? What is your preferred protocol for Git operations on this host? SSH"
    echo "? Generate a new SSH key to add to your GitHub account? Yes"
    echo "? Enter a passphrase for your new SSH key (Optional)"
    echo "? Title for your SSH key: nmm-dev-server"
    echo "? How would you like to authenticate GitHub CLI? Login with a web browser"
    echo
    echo "! First copy your one-time code: 673A-F6DF"
    echo "Press Enter to open github.com in your browser..."
    echo "! Failed opening a web browser at https://github.com/login/device"
    echo "exec: \"xdg-open,x-www-browser,www-browser,wslview\": executable file not found in \$PATH"
    echo "Please try entering the URL in your browser manually"
    echo "✓ Authentication complete."
    echo "- gh config set -h github.com git_protocol ssh"
    echo "✓ Configured git protocol"
    echo "! Authentication credentials saved in plain text"
    echo "✓ Uploaded the SSH key to your GitHub account: /home/ubuntu/.ssh/id_ed25519.pub"
    echo "✓ Logged in as greyHairChooseLife"
fi

echo "🎉 [Setup] System provisioning complete."
