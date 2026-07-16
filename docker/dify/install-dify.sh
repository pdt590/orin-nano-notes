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
# Configure .env
#############################################

echo "Configuring .env..."

# Update if exists, otherwise append
grep -q "^EXPOSE_NGINX_PORT=" .env \
    && sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=18080/' .env \
    || echo "EXPOSE_NGINX_PORT=18080" >> .env

grep -q "^EXPOSE_NGINX_SSL_PORT=" .env \
    && sed -i 's/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=18443/' .env \
    || echo "EXPOSE_NGINX_SSL_PORT=18443" >> .env

grep -q "^COMPOSE_PROJECT_NAME=" .env \
    && sed -i 's/^COMPOSE_PROJECT_NAME=.*/COMPOSE_PROJECT_NAME=dify/' .env \
    || echo "COMPOSE_PROJECT_NAME=dify" >> .env

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
echo "  http://localhost:18080/install"
echo "or"
echo "  http://$IP:18080/install"
echo "==========================================="
