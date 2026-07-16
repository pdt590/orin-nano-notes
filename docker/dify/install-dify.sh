#!/usr/bin/env bash
set -e

#############################################
# Dify Docker Compose Installer
#############################################

DIFY_DIR="$(pwd)/dify-repo"

echo "===================================="
echo " Installing Dify"
echo "===================================="

#############################################
# Check Docker
#############################################

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "Error: Docker Compose plugin is not installed."
    exit 1
fi

#############################################
# Clone Dify
#############################################

if [ ! -d "$DIFY_DIR" ]; then
    echo "Cloning Dify..."
    git clone https://github.com/langgenius/dify.git "$DIFY_DIR"
else
    echo "Using existing Dify directory: $DIFY_DIR"
fi

#############################################
# Go to docker directory
#############################################

cd "$DIFY_DIR/docker"

#############################################
# Create .env
#############################################

if [ ! -f ".env" ]; then
    echo "Creating .env..."
    cp .env.example .env
fi

#############################################
# Pull images
#############################################

echo "Pulling Docker images..."
docker compose pull

#############################################
# Start Dify
#############################################

echo "Starting Dify..."
docker compose up -d

#############################################
# Wait for startup
#############################################

echo "Waiting for containers..."
sleep 20

docker compose ps

#############################################
# Done
#############################################

IP=$(hostname -I | awk '{print $1}')

echo
echo "==========================================="
echo "Dify has been started successfully!"
echo
echo "Open your browser:"
echo "  http://localhost/install"
echo "or"
echo "  http://$IP/install"
echo "==========================================="