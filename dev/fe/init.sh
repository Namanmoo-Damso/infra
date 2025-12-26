#!/bin/bash

# AI 서버 SSH 터널링 설정 (백그라운드 실행)
# 예: 로컬 8000 포트를 AI 서버의 8000 포트로 포워딩
echo "Setting up SSH tunnel to AI Server..."
# ssh -N -L 8000:localhost:8000 user@ai-stable-server &
# TUNNEL_PID=$!

echo "Starting FE Development Environment..."
docker-compose up -d

echo "FE Dev Server is running at http://localhost:3000"
echo "To stop: docker-compose down"

# 터널링 종료 처리는 별도 필요
