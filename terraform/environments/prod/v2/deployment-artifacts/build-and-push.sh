#!/bin/bash
set -e

# Configuration
VERSION="v2"
ORG="namanmoo-damso"
GITHUB_BASE="https://github.com/$ORG"
WORK_DIR="./build-workspace"

# Git reference (branch, tag, or commit hash)
# Leave empty for latest main branch
GIT_REF="${GIT_REF}"

# Login to GitHub Container Registry
echo "📦 Logging in to GHCR..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin

echo "🚀 Building and pushing images with version: $VERSION"
echo "=============================================="

# Clone or update repositories
echo "📥 Preparing repositories..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

for repo in ops-api ops-web ops-agent; do
    echo "  Cloning $repo..."
    git clone "$GITHUB_BASE/$repo.git"
    cd "$repo"
    git checkout "$GIT_REF"
    cd ..
done

# Build and push api
echo ""
echo "🔨 Building api..."
cd ops-api
docker build -t ghcr.io/$ORG/api:$VERSION -f Dockerfile .
echo "📤 Pushing api..."
docker push ghcr.io/$ORG/api:$VERSION
cd ..

# Build and push web
echo ""
echo "🔨 Building web..."
cd ops-web
docker build \
    --build-arg NEXT_PUBLIC_API_BASE=https://sodam.store \
    --build-arg NEXT_PUBLIC_ROOM_NAME=demo-room \
    --build-arg NEXT_PUBLIC_NAVER_MAP_CLIENT_ID=98ncl9cv85 \
    --build-arg NEXT_PUBLIC_KAKAO_CLIENT_ID=ac893137a826fee92d16cf6e0b7039ee \
    --build-arg NEXT_PUBLIC_GOOGLE_CLIENT_ID=810981442237-ub7rgb46fkf31he5k383dhnb4m4tmqql.apps.googleusercontent.com \
    -t ghcr.io/$ORG/web:$VERSION -f Dockerfile .
echo "📤 Pushing web..."
docker push ghcr.io/$ORG/web:$VERSION
cd ..

# Build and push ops-agent
echo ""
echo "🔨 Building agent..."
cd ops-agent
docker build -t ghcr.io/$ORG/agent:$VERSION -f Dockerfile .
echo "📤 Pushing agent..."
docker push ghcr.io/$ORG/agent:$VERSION
cd ..

echo ""
echo "✅ All images built and pushed successfully!"
echo "=============================================="
echo "Images:"
echo "  - ghcr.io/$ORG/api:$VERSION"
echo "  - ghcr.io/$ORG/web:$VERSION"
echo "  - ghcr.io/$ORG/agent:$VERSION"
echo ""
echo "To pull on deployment instance:"
echo "  docker pull ghcr.io/$ORG/api:$VERSION"
echo "  docker pull ghcr.io/$ORG/web:$VERSION"
echo "  docker pull ghcr.io/$ORG/agent:$VERSION"
