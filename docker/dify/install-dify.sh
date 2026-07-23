#!/usr/bin/env bash
set -e

########################################
# Colors
########################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

#############################################
# Dify Docker Compose Installer
#############################################

REPO_URL="https://github.com/langgenius/dify.git"
REPO_DIR="dify-repo"
DOCKER_DIR="dify-docker"
ENV_FILE=".env"

info "Installing Dify..."

#############################################
# Check Docker
#############################################

info "Checking docker..."

if ! command -v docker >/dev/null 2>&1; then
    error "Error: Docker is not installed."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    error "Error: Docker Compose plugin is not installed."
    exit 1
fi

########################################
# Cleanup Existing Directories
########################################

if [ -d "$REPO_DIR" ]; then
    warn "$REPO_DIR already exists."
    read -rp "Delete it? (y/N): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_DIR"
    else
        error "Installation cancelled."
        exit 1
    fi
fi

if [ -d "$DOCKER_DIR" ]; then
    warn "$DOCKER_DIR already exists."
    read -rp "Delete it? (y/N): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm -rf "$DOCKER_DIR"
    else
        error "Installation cancelled."
        exit 1
    fi
fi

#############################################
# Clone Dify
#############################################

info "Downloading dify repository..."

git clone \
    --filter=blob:none \
    --no-checkout \
    --depth=1 \
    --quiet \
    "$REPO_URL" \
	"$REPO_DIR"

cd "$REPO_DIR"

git sparse-checkout init --cone
git sparse-checkout set docker
git checkout --quiet

cd ..

#############################################
# Create Dify Docker Directory
#############################################

info "Creating docker directory..."

mkdir "$DOCKER_DIR"

cp -rf "$REPO_DIR/docker/"* "$DOCKER_DIR"

cp "$REPO_DIR/docker/.env.example" "$DOCKER_DIR/.env"

cd "$DOCKER_DIR"

#############################################
# Configure .env
#############################################

info "Configuring .env..."

set_env_var() {
    info "Setting $1=$2"

    local key="$1"
    local value="$2"
    local file="${3:-$ENV_FILE}"

    # Escape characters for sed replacement
    local escaped_value
    escaped_value=$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')

    if grep -qE "^${key}=" "$file"; then
        # Update existing variable
        sed -i "s/^${key}=.*/${key}=${escaped_value}/" "$file"
    else
        # Add new variable
        echo "${key}=${value}" >> "$file"
    fi
}

set_env_var "EXPOSE_NGINX_PORT" "18080"
set_env_var "EXPOSE_NGINX_SSL_PORT" "18443"
set_env_var "COMPOSE_PROJECT_NAME" "dify"
set_env_var "TRIGGER_URL" "https://dify.hubplus.net"
set_env_var "CONSOLE_API_URL" "https://dify.hubplus.net"
set_env_var "CONSOLE_WEB_URL" "https://dify.hubplus.net"

#############################################
# Pull images
#############################################

info "Pulling Docker images..."
docker compose pull

#############################################
# Start Dify
#############################################

info "Starting Dify..."
docker compose up -d

#############################################
# Wait for startup
#############################################

info "Waiting for containers..."
sleep 20

docker compose ps

#############################################
# Done
#############################################

IP=$(hostname -I | awk '{print $1}')

info "Dify has been started successfully!"
info "Open your browser:"
info "  http://localhost:18080/install"
info "or"
info "  http://$IP:18080/install"
