#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GHCR_ORG="namanmoo-damso"
TAG="v4"
REPO_URLS=(
    "https://github.com/Namanmoo-Damso/ops-api.git"
    "https://github.com/Namanmoo-Damso/ops-web.git"
    "https://github.com/Namanmoo-Damso/ops-agent.git"
)

# Available services (v4: vLLM uses official image, not built here)
AVAILABLE_SERVICES=("api" "web" "agent-ai-server" "agent" "agent-kma-mcp")
SERVICES_TO_BUILD=()

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

show_usage() {
    echo "Usage: $0 [service1] [service2] ..."
    echo ""
    echo "Available services:"
    for service in "${AVAILABLE_SERVICES[@]}"; do
        echo "  - $service"
    done
    echo ""
    echo "Examples:"
    echo "  $0                    # Build and push all services"
    echo "  $0 api                # Build and push only api"
    echo "  $0 api web            # Build and push api and web"
    echo "  $0 agent-ai-server agent    # Build and push agent-ai-server and agent"
    echo ""
    echo "Note: vLLM uses official vllm/vllm-openai:latest image from Docker Hub."
    echo "      It is pulled directly at deployment time, not built here."
    exit 1
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    # No arguments - build all services
    SERVICES_TO_BUILD=("${AVAILABLE_SERVICES[@]}")
else
    # Validate provided services
    for arg in "$@"; do
        if [[ "$arg" == "-h" ]] || [[ "$arg" == "--help" ]]; then
            show_usage
        fi

        valid=false
        for service in "${AVAILABLE_SERVICES[@]}"; do
            if [[ "$arg" == "$service" ]]; then
                valid=true
                SERVICES_TO_BUILD+=("$arg")
                break
            fi
        done

        if [ "$valid" = false ]; then
            log_error "Invalid service: $arg"
            echo ""
            show_usage
        fi
    done
fi

# Change to script directory
cd "$(dirname "$0")"

log_info "=== v4 Image Build and Push Script ==="
log_info "GHCR Organization: $GHCR_ORG"
log_info "Tag: $TAG"
echo -e "${BLUE}Services to build:${NC} ${SERVICES_TO_BUILD[*]}"
echo ""

# Step 1: Clean and initialize repos directory
log_info "Step 1: Cleaning repos directory..."
rm -rf repos/
mkdir -p repos/
log_info "repos/ directory initialized"
echo ""

# Step 2: Clone repositories with tag
log_info "Step 2: Cloning repositories (tag: $TAG)..."
for url in "${REPO_URLS[@]}"; do
    repo_name=$(basename "$url" .git)
    log_info "Cloning $repo_name..."

    if git clone --branch "$TAG" --depth 1 "$url" "repos/$repo_name" 2>&1; then
        log_info "$repo_name cloned successfully"
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
log_info "GHCR credentials found"
echo ""

# Step 4: Login to GHCR
log_info "Step 4: Logging into GHCR..."
if echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin; then
    log_info "Successfully logged into GHCR"
else
    log_error "Failed to login to GHCR"
    exit 1
fi
echo ""

# Step 5: Build images
log_info "Step 5: Building images with low CPU priority..."
log_warn "This may take 10-30 minutes depending on your machine"
log_info "Using nice -n 19 (lowest CPU priority) and ionice -c 3 (idle I/O priority)"

build_cmd="nice -n 19 ionice -c 3 docker compose -f docker-compose.build.yml build"
for service in "${SERVICES_TO_BUILD[@]}"; do
    build_cmd="$build_cmd $service"
done

if $build_cmd; then
    log_info "Selected images built successfully"
else
    log_error "Failed to build images"
    exit 1
fi
echo ""

# Step 6: Push images to GHCR
log_info "Step 6: Pushing images to GHCR with low CPU priority..."

push_cmd="nice -n 19 ionice -c 3 docker compose -f docker-compose.build.yml push"
for service in "${SERVICES_TO_BUILD[@]}"; do
    push_cmd="$push_cmd $service"
done

if $push_cmd; then
    log_info "Selected images pushed successfully"
else
    log_error "Failed to push images"
    exit 1
fi
echo ""

# Summary
log_info "=== Build and Push Complete ==="
log_info "Images pushed to GHCR:"

for service in "${SERVICES_TO_BUILD[@]}"; do
    case "$service" in
        "api")
            echo "  - ghcr.io/$GHCR_ORG/ops-api:$TAG"
            ;;
        "web")
            echo "  - ghcr.io/$GHCR_ORG/ops-web:$TAG"
            ;;
        "agent-ai-server")
            echo "  - ghcr.io/$GHCR_ORG/ops-agent-ai-server:$TAG"
            ;;
        "agent")
            echo "  - ghcr.io/$GHCR_ORG/ops-agent:$TAG (used by agent, transcript-storage, vllm-warmup)"
            ;;
        "agent-kma-mcp")
            echo "  - ghcr.io/$GHCR_ORG/ops-agent-kma-mcp:$TAG"
            ;;
    esac
done
echo ""
log_info "Note: vLLM uses official vllm/vllm-openai:latest from Docker Hub"
echo ""
log_info "Next steps:"
echo "  1. Deploy to EC2 using deployment scripts"
echo "  2. Verify images are pulled correctly"
