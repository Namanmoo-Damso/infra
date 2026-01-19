#!/bin/bash
set -euo pipefail

# =============================================================================
# Common initialization script for all EC2 instances
# =============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting common initialization..."

# -----------------------------------------------------------------------------
# Update system
# -----------------------------------------------------------------------------
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# -----------------------------------------------------------------------------
# Install Portal (spatium portae)
# -----------------------------------------------------------------------------
log "Installing Portal..."
curl -sL portal.spatiumportae.com | bash

# -----------------------------------------------------------------------------
# Install Docker
# -----------------------------------------------------------------------------
log "Installing Docker..."

# Install prerequisites
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# -----------------------------------------------------------------------------
# Configure Docker to run without sudo
# -----------------------------------------------------------------------------
log "Configuring Docker permissions..."

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Enable Docker service
systemctl enable docker
systemctl start docker

log "Common initialization complete!"
log "Note: Log out and log back in for docker group changes to take effect"
