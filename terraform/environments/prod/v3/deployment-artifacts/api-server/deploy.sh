#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="API Server"
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

log_info "✓ Docker and Docker Compose are available"
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
log_info "This may take a few minutes depending on network speed"
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
if docker compose -f "$COMPOSE_FILE" up -d; then
    log_info "✓ Containers started"
else
    log_error "Failed to start containers"
    exit 1
fi
echo ""

# Step 6: Wait for health checks
log_step "Step 6: Waiting for services to be healthy..."
log_info "Checking API server health (timeout: 60s)..."

TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "healthy"; then
        log_info "✓ Services are healthy"
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    echo -n "."
done
echo ""

if [ $ELAPSED -ge $TIMEOUT ]; then
    log_warn "Health check timeout reached. Check service status manually."
fi
echo ""

# Step 7: Show status
log_step "Step 7: Service Status"
docker compose -f "$COMPOSE_FILE" ps
echo ""

# Step 8: Show recent logs
log_step "Step 8: Recent Logs (last 20 lines)"
docker compose -f "$COMPOSE_FILE" logs --tail=20
echo ""

# Summary
log_info "=== Deployment Complete ==="
log_info "Services:"
echo "  - API Server: http://localhost:8080"
echo "  - Indexing Worker: background process"
echo ""
log_info "Useful commands:"
echo "  - View logs: docker compose -f $COMPOSE_FILE logs -f"
echo "  - Check status: docker compose -f $COMPOSE_FILE ps"
echo "  - Restart: docker compose -f $COMPOSE_FILE restart"
echo "  - Stop: docker compose -f $COMPOSE_FILE down"
