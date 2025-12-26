#!/bin/bash

echo "Starting BE Development Environment..."

# 필요한 네트워크 생성 (없을 경우)
docker network create dev-network 2> /dev/null || true

docker-compose up -d

echo "BE Server running with Livekit and DBs."
echo "Livekit Dashboard: http://localhost:7880"
