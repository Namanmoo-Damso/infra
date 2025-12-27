#!/bin/bash

# ==========================================
# 설정 (사용 환경에 맞게 수정하세요)
# ==========================================
IMAGE_NAME="ec2-dev-server-controller"
PEM_FILE="dev-server.pem"  # 현재 디렉토리에 있는 키 파일 이름
LOG_FILE=".server_output.log" # 임시 로그 파일
# ==========================================

# 1. PEM 파일 확인
if [ ! -f "$PEM_FILE" ]; then
    echo "❌ Error: 현재 디렉토리에서 '$PEM_FILE' 파일을 찾을 수 없습니다."
    echo "   스크립트 상단의 PEM_FILE 변수를 확인해주세요."
    exit 1
fi

# 2. 사용자 입력 받기
echo "========================================"
echo "   EC2 개발 서버 관리자 (Docker 기반)"
echo "========================================"
echo "1) Start (서버 켜기 + SSH 접속)"
echo "2) Stop  (서버 끄기)"
echo "========================================"
read -p "실행할 작업을 선택하세요 (1 또는 2): " choice

case $choice in
    1 | start | Start)
        ACTION="start"
        ;;
    2 | stop | Stop)
        ACTION="stop"
        ;;
    *)
        echo "❌ 잘못된 입력입니다. 스크립트를 종료합니다."
        exit 1
        ;;
esac

echo ""
echo "🐳 Docker 이미지를 빌드 중입니다..."
docker build -q -t $IMAGE_NAME . > /dev/null

if [ $? -ne 0 ]; then
    echo "❌ Docker 빌드 실패! Dockerfile을 확인해주세요."
    exit 1
fi
echo "✅ 빌드 완료."

echo ""
echo "🚀 '$ACTION' 작업을 시작합니다..."
echo "----------------------------------------"

# 3. Docker 실행
# -v ... : PEM 파일을 컨테이너 내부의 /root/.ssh/id_rsa 로 마운트합니다.
docker run --rm \
    --env-file .env \
    -e ACTION=$ACTION \
    -v "$(pwd)/$PEM_FILE":/root/.ssh/id_rsa \
    $IMAGE_NAME | tee "$LOG_FILE"

echo "----------------------------------------"
echo "✨ 작업이 종료되었습니다."

# 4. Start 액션일 경우, 자동으로 SSH 접속 시도
if [ "$ACTION" == "start" ]; then
    # 로그 파일에서 접속 정보 추출 (__SSH_CONNECT_TARGET__=user@ip)
    TARGET=$(grep "__SSH_CONNECT_TARGET__=" "$LOG_FILE" | cut -d'=' -f2 | tr -d '\r')

    if [ -n "$TARGET" ]; then
        echo ""
        echo "🔌 서버가 준비되었습니다. SSH 접속을 시작합니다..."
        echo "   Command: ssh -i $PEM_FILE $TARGET"
        echo "----------------------------------------"

        # 실제 SSH 접속 (Host 머신에서 실행됨)
        ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -i "$PEM_FILE" "$TARGET"
    else
        echo "⚠️ SSH 접속 정보를 찾을 수 없습니다. (서버 기동 실패 또는 타임아웃)"
    fi
fi

# 임시 로그 파일 삭제
rm -f "$LOG_FILE"
