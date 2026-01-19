#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="AI Agent"
COMPOSE_FILE="docker-compose.yml"

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

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

# Change to script directory
cd "$(dirname "$0")"

log_info "=== $SERVICE_NAME Deployment ==="
echo ""

# Step 1: Verify prerequisites
log_step "Step 1: Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    log_error "Docker Compose is not installed"
    exit 1
fi

# Check GPU availability
if ! command -v nvidia-smi &> /dev/null; then
    log_error "nvidia-smi is not available. GPU drivers may not be installed."
    exit 1
fi

log_info "GPU Information:"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo ""

log_info "✓ Docker, Docker Compose, and GPU are available"
echo ""

# Step 2: GHCR Login (optional, for private images)
log_step "Step 2: GHCR Authentication..."
if [ -n "${GHCR_USERNAME:-}" ] && [ -n "${GHCR_TOKEN:-}" ]; then
    log_info "GHCR credentials found, logging in..."
    if echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin 2>&1 | grep -q "Login Succeeded"; then
        log_info "✓ Successfully logged into GHCR"
    else
        log_warn "GHCR login failed, continuing anyway (images might be public)"
    fi
else
    log_warn "No GHCR credentials found (GHCR_USERNAME/GHCR_TOKEN)"
    log_info "If images are private, set environment variables:"
    echo "  export GHCR_USERNAME=<your-github-username>"
    echo "  export GHCR_TOKEN=<your-github-pat>"
    log_info "Continuing with public image pull..."
fi
echo ""

# Step 3: Pull images
log_step "Step 3: Pulling Docker images..."
log_warn "This may take 10-20 minutes (STT: ~2GB, Ollama: ~5-6GB)"
if docker compose -f "$COMPOSE_FILE" pull; then
    log_info "✓ Images pulled successfully"
else
    log_error "Failed to pull images"
    exit 1
fi
echo ""

# Step 4: Stop existing containers (if any)
log_step "Step 4: Stopping existing containers..."
if docker compose -f "$COMPOSE_FILE" down 2>/dev/null; then
    log_info "✓ Existing containers stopped"
else
    log_info "No existing containers to stop"
fi
echo ""

# Step 5: Start containers
log_step "Step 5: Starting containers..."
log_warn "AI models will load during startup (may take 1-2 minutes per service)"
if docker compose -f "$COMPOSE_FILE" up -d; then
    log_info "✓ Containers started"
else
    log_error "Failed to start containers"
    exit 1
fi
echo ""

# Step 6: Wait for health checks
log_step "Step 6: Waiting for services to be healthy..."
log_info "This may take 2-3 minutes as models load into GPU memory..."
log_info "Progress: STT (30s) → Ollama (60s) → Agent (10s) → Others (10s)"

TIMEOUT=180
ELAPSED=0
HEALTHY_COUNT=0
TOTAL_SERVICES=5

while [ $ELAPSED -lt $TIMEOUT ]; do
    HEALTHY_COUNT=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep -c '"Health":"healthy"' || echo 0)

    if [ "$HEALTHY_COUNT" -eq "$TOTAL_SERVICES" ]; then
        log_info "✓ All services are healthy ($HEALTHY_COUNT/$TOTAL_SERVICES)"
        break
    fi

    # Show progress every 10 seconds
    if [ $((ELAPSED % 10)) -eq 0 ]; then
        echo -n "[$ELAPSED/${TIMEOUT}s] Healthy: $HEALTHY_COUNT/$TOTAL_SERVICES "
    fi

    sleep 2
    ELAPSED=$((ELAPSED + 2))
    echo -n "."
done
echo ""

if [ $ELAPSED -ge $TIMEOUT ]; then
    log_warn "Health check timeout reached. Some services may still be starting."
    log_info "Current status:"
    docker compose -f "$COMPOSE_FILE" ps
fi
echo ""

# Step 7: Show status
log_step "Step 7: Service Status"
docker compose -f "$COMPOSE_FILE" ps
echo ""

# Step 8: Check GPU usage
log_step "Step 8: GPU Usage"
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
echo ""

# Step 9: Show recent logs
log_step "Step 9: Recent Logs (last 10 lines per service)"
docker compose -f "$COMPOSE_FILE" logs --tail=10
echo ""

# Summary
log_info "=== Deployment Complete ==="
log_info "Services:"
echo "  - STT (Whisper): http://localhost:8000"
echo "  - Ollama (LLM): http://localhost:11434"
echo "  - AI Agent: connected to Livekit"
echo "  - Transcript Storage: background worker"
echo "  - KMA MCP: http://localhost:8001"
echo ""
log_info "Useful commands:"
echo "  - View logs: docker compose -f $COMPOSE_FILE logs -f [service-name]"
echo "  - Check GPU: nvidia-smi"
echo "  - Check status: docker compose -f $COMPOSE_FILE ps"
echo "  - Restart service: docker compose -f $COMPOSE_FILE restart [service-name]"
echo "  - Stop all: docker compose -f $COMPOSE_FILE down"
