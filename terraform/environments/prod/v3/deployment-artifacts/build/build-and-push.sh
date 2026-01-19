#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GHCR_ORG="namanmoo-damso"
TAG="v3"
REPO_URLS=(
    "https://github.com/Namanmoo-Damso/ops-api.git"
    "https://github.com/Namanmoo-Damso/ops-web.git"
    "https://github.com/Namanmoo-Damso/ops-agent.git"
)

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to script directory
cd "$(dirname "$0")"

log_info "=== v3 Image Build and Push Script ==="
log_info "GHCR Organization: $GHCR_ORG"
log_info "Tag: $TAG"
echo ""

# Step 1: Clean and initialize repos directory
log_info "Step 1: Cleaning repos directory..."
rm -rf repos/
mkdir -p repos/
log_info "✓ repos/ directory initialized"
echo ""

# Step 2: Clone repositories with tag
log_info "Step 2: Cloning repositories (tag: $TAG)..."
for url in "${REPO_URLS[@]}"; do
    repo_name=$(basename "$url" .git)
    log_info "Cloning $repo_name..."

    if git clone --branch "$TAG" --depth 1 "$url" "repos/$repo_name" 2>&1; then
        log_info "✓ $repo_name cloned successfully"
    else
        log_error "Failed to clone $repo_name with tag $TAG"
        log_warn "Make sure the tag '$TAG' exists in all repositories"
        exit 1
    fi
done
echo ""

# Step 3: Verify GHCR credentials
log_info "Step 3: Verifying GHCR credentials..."
if [ -z "${GHCR_USERNAME:-}" ] || [ -z "${GHCR_TOKEN:-}" ]; then
    log_error "GHCR credentials not found"
    echo "Please set environment variables:"
    echo "  export GHCR_USERNAME=<your-github-username>"
    echo "  export GHCR_TOKEN=<your-github-pat>"
    exit 1
fi
log_info "✓ GHCR credentials found"
echo ""

# Step 4: Login to GHCR
log_info "Step 4: Logging into GHCR..."
if echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin; then
    log_info "✓ Successfully logged into GHCR"
else
    log_error "Failed to login to GHCR"
    exit 1
fi
echo ""

# Step 5: Build images
log_info "Step 5: Building images with low CPU priority..."
log_warn "This may take 10-30 minutes depending on your machine"
log_info "Using nice -n 19 (lowest CPU priority) and ionice -c 3 (idle I/O priority)"
if nice -n 19 ionice -c 3 docker compose -f docker-compose.build.yml build; then
    log_info "✓ All images built successfully"
else
    log_error "Failed to build images"
    exit 1
fi
echo ""

# Step 6: Push images to GHCR
log_info "Step 6: Pushing images to GHCR with low CPU priority..."
if nice -n 19 ionice -c 3 docker compose -f docker-compose.build.yml push; then
    log_info "✓ All images pushed successfully"
else
    log_error "Failed to push images"
    exit 1
fi
echo ""

# Summary
log_info "=== Build and Push Complete ==="
log_info "Images pushed to GHCR:"
echo "  - ghcr.io/$GHCR_ORG/ops-api:$TAG"
echo "  - ghcr.io/$GHCR_ORG/ops-web:$TAG"
echo "  - ghcr.io/$GHCR_ORG/ops-agent-stt:$TAG"
echo "  - ghcr.io/$GHCR_ORG/ops-agent-ollama:$TAG"
echo "  - ghcr.io/$GHCR_ORG/ops-agent:$TAG (used by both agent and transcript-storage)"
echo "  - ghcr.io/$GHCR_ORG/ops-agent-kma-mcp:$TAG"
echo ""
log_info "Next steps:"
echo "  1. Deploy to EC2 using deployment scripts"
echo "  2. Verify images are pulled correctly"
