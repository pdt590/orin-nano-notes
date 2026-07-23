#!/usr/bin/env bash
set -e

#############################################
# Dify Docker Compose Installer
#############################################

REPO_URL="https://github.com/langgenius/dify.git"
REPO_DIR="dify-repo"
DOCKER_DIR="dify-docker"
ENV_FILE=".env"

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

########################################
# Cleanup Existing Directories
########################################

if [ -d "$REPO_DIR" ]; then
    echo "$REPO_DIR already exists."
    read -rp "Delete it? (y/N): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_DIR"
    else
        error "Installation cancelled."
        exit 1
    fi
fi

if [ -d "$DOCKER_DIR" ]; then
    echo "$DOCKER_DIR already exists."
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

echo "Downloading dify repository..."

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

echo "Creating docker directory..."

mkdir "$DOCKER_DIR"

cp -rf "$REPO_DIR/docker/"* "$DOCKER_DIR"

cp "$REPO_DIR/docker/.env.example" "$DOCKER_DIR/.env"

cd "$DOCKER_DIR"

#############################################
# Configure .env
#############################################

echo "Configuring .env..."

set_env_var() {
    local env_file="$1"
    local key="$2"
    local value="$3"

    # Create file if it doesn't exist
    touch "$env_file"

    # Escape characters for sed replacement
    local escaped_value
    escaped_value=$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')

    if grep -qE "^${key}=" "$env_file"; then
        # Replace existing value
        sed -i "s/^${key}=.*/${key}=${escaped_value}/" "$env_file"
    else
        # Add new variable
        printf "\n%s=%s\n" "$key" "$value" >> "$env_file"
    fi
}

set_env_var "$ENV_FILE" "EXPOSE_NGINX_PORT" "18080"
set_env_var "$ENV_FILE" "EXPOSE_NGINX_SSL_PORT" "18443"
set_env_var "$ENV_FILE" "COMPOSE_PROJECT_NAME" "dify"
set_env_var "$ENV_FILE" "TRIGGER_URL" "https://dify.hubplus.net"

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
