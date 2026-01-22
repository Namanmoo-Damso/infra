#!/bin/bash
set -euo pipefail

# =============================================================================
# AI Agent Server initialization
# =============================================================================
# Note: Deep Learning AMI already has GPU drivers, NVIDIA toolkit, and Docker
# Only need to install Portal and configure Docker permissions

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting AI Agent server initialization..."

# -----------------------------------------------------------------------------
# Install Portal
# -----------------------------------------------------------------------------
log "Installing Portal..."
curl -sL portal.spatiumportae.com | bash

# -----------------------------------------------------------------------------
# Configure Docker to run without sudo
# -----------------------------------------------------------------------------
log "Configuring Docker permissions for ubuntu user..."
usermod -aG docker ubuntu

log "AI Agent server initialization complete!"
log "Note: Log out and log back in for docker group changes to take effect"
