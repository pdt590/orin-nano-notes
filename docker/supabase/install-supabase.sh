#!/usr/bin/env bash

set -Eeuo pipefail

########################################
# Configuration
########################################

REPO_URL="https://github.com/supabase/supabase"
REPO_DIR="supabase-repo"
DOCKER_DIR="docker"
ENV_FILE=".env"

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

########################################
# Check Requirements
########################################

info "Checking requirements..."

command -v git >/dev/null || {
    error "Git is not installed."
    exit 1
}

docker compose version >/dev/null || {
    error "Docker Compose is not installed."
    exit 1
}

########################################
# Cleanup Existing Repository
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

########################################
# Existing Project Directory
########################################

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

########################################
# Clone Repository
########################################

info "Downloading Supabase repository..."

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

########################################
# Create Project
########################################

info "Creating project..."

mkdir "$DOCKER_DIR"

cp -rf "$REPO_DIR/docker/"* "$DOCKER_DIR"

cp "$REPO_DIR/docker/.env.example" "$DOCKER_DIR/.env"

########################################
# Enter Project
########################################

cd "$DOCKER_DIR"

########################################
# Pull Images
########################################

info "Pulling Docker images..."

docker compose pull

########################################
# Generate Secrets
########################################

info "Generating passwords and secrets..."

sh utils/generate-keys.sh

########################################
# Generate Auth Keys
########################################

info "Generating API keys..."

sh utils/add-new-auth-keys.sh

########################################
# Configure User Environment
########################################

info "Configure Supabase settings"

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

set_env_var "DASHBOARD_USERNAME" "admin"
set_env_var "DASHBOARD_PASSWORD" "Mot23456"
set_env_var "KONG_HTTP_PORT" "8345"
set_env_var "KONG_HTTPS_PORT" "8543"

########################################
# Start Supabase
########################################

info "Starting Supabase..."

sh run.sh start
