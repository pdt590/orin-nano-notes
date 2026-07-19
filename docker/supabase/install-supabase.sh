#!/usr/bin/env bash

set -Eeuo pipefail

########################################
# Configuration
########################################

REPO_URL="https://github.com/supabase/supabase"
REPO_DIR="supabase-repo"
PROJECT_DIR="supabase-project"

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

if [ -d "$PROJECT_DIR" ]; then
    warn "$PROJECT_DIR already exists."
    read -rp "Delete it? (y/N): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_DIR"
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

mkdir "$PROJECT_DIR"

cp -rf "$REPO_DIR/docker/"* "$PROJECT_DIR"

cp "$REPO_DIR/docker/.env.example" "$PROJECT_DIR/.env"

########################################
# Enter Project
########################################

cd "$PROJECT_DIR"

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

# Read current values
CURRENT_DASHBOARD_USERNAME=$(grep "^DASHBOARD_USERNAME=" .env | cut -d '=' -f2 || true)
CURRENT_DASHBOARD_PASSWORD=$(grep "^DASHBOARD_PASSWORD=" .env | cut -d '=' -f2 || true)
CURRENT_KONG_HTTP_PORT=$(grep "^KONG_HTTP_PORT=" .env | cut -d '=' -f2 || true)
CURRENT_KONG_HTTPS_PORT=$(grep "^KONG_HTTPS_PORT=" .env | cut -d '=' -f2 || true)


update_env_value() {
    local key=$1
    local value=$2

    if grep -q "^${key}=" .env; then
        sed -i "s|^${key}=.*|${key}=${value}|" .env
    else
        echo "${key}=${value}" >> .env
    fi
}


########################################
# Dashboard Username
########################################

read -rp \
"Change DASHBOARD_USERNAME (current: ${CURRENT_DASHBOARD_USERNAME})? Enter new value or press Enter to keep: " \
NEW_DASHBOARD_USERNAME

if [ -n "$NEW_DASHBOARD_USERNAME" ]; then
    update_env_value "DASHBOARD_USERNAME" "$NEW_DASHBOARD_USERNAME"
fi


########################################
# Dashboard Password
########################################

read -rsp \
"Change DASHBOARD_PASSWORD (current hidden)? Enter new password or press Enter to keep: " \
NEW_DASHBOARD_PASSWORD

echo

if [ -n "$NEW_DASHBOARD_PASSWORD" ]; then
    update_env_value "DASHBOARD_PASSWORD" "$NEW_DASHBOARD_PASSWORD"
fi


########################################
# Kong HTTP Port
########################################

read -rp \
"Change KONG_HTTP_PORT (current: ${CURRENT_KONG_HTTP_PORT})? Enter new port or press Enter to keep: " \
NEW_KONG_HTTP_PORT

if [ -n "$NEW_KONG_HTTP_PORT" ]; then
    update_env_value "KONG_HTTP_PORT" "$NEW_KONG_HTTP_PORT"
fi


########################################
# Kong HTTPS Port
########################################

read -rp \
"Change KONG_HTTPS_PORT (current: ${CURRENT_KONG_HTTPS_PORT})? Enter new port or press Enter to keep: " \
NEW_KONG_HTTPS_PORT

if [ -n "$NEW_KONG_HTTPS_PORT" ]; then
    update_env_value "KONG_HTTPS_PORT" "$NEW_KONG_HTTPS_PORT"
fi

########################################
# Update URLs based on Kong HTTP Port
########################################

KONG_HTTP_PORT=$(grep "^KONG_HTTP_PORT=" .env | cut -d '=' -f2)

info "Updating Supabase URLs..."

update_env_value \
    "SUPABASE_PUBLIC_URL" \
    "http://localhost:${KONG_HTTP_PORT}"

update_env_value \
    "API_EXTERNAL_URL" \
    "http://localhost:${KONG_HTTP_PORT}/auth/v1"

########################################
# Start Supabase
########################################

info "Starting Supabase..."

sh run.sh start
