#!/usr/bin/env bash
# =============================================================================
# TechOps Platform — Setup Script
# Bootstraps the entire platform with sane defaults
# Usage: chmod +x setup.sh && ./setup.sh
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
header()  { echo -e "\n${BOLD}${BLUE}══ $* ══${NC}\n"; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}"
cat << 'EOF'
  ████████╗███████╗ ██████╗██╗  ██╗ ██████╗ ██████╗ ███████╗
     ██╔══╝██╔════╝██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔════╝
     ██║   █████╗  ██║     ███████║██║   ██║██████╔╝███████╗
     ██║   ██╔══╝  ██║     ██╔══██║██║   ██║██╔═══╝ ╚════██║
     ██║   ███████╗╚██████╗██║  ██║╚██████╔╝██║     ███████║
     ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝
                   Technical Operations Platform v1.0.0
EOF
echo -e "${NC}"

# ── Pre-flight checks ─────────────────────────────────────────────────────────
header "Pre-flight checks"

check_command() {
    if ! command -v "$1" &>/dev/null; then
        error "$1 is required but not installed. Please install it first."
    fi
    success "$1 found: $(command -v "$1")"
}

check_command docker
check_command curl
check_command openssl

# Check Docker Compose (v2 plugin style)
if docker compose version &>/dev/null; then
    success "Docker Compose v2 found"
elif docker-compose version &>/dev/null; then
    warn "Docker Compose v1 found. Recommend upgrading to v2 (docker compose)."
else
    error "Docker Compose not found. Install it with: sudo apt install docker-compose-plugin"
fi

# Check Docker daemon is running
if ! docker info &>/dev/null; then
    error "Docker daemon is not running. Start it with: sudo systemctl start docker"
fi

success "All pre-flight checks passed"

# ── Environment setup ─────────────────────────────────────────────────────────
header "Environment configuration"

if [[ -f .env ]]; then
    warn ".env file already exists. Skipping generation."
    warn "Delete .env and re-run setup to regenerate secrets."
else
    info "Generating .env from .env.example..."
    cp .env.example .env

    # Generate all secrets automatically
    info "Generating cryptographic secrets..."

    POSTGRES_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)
    REDIS_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)
    VIKUNJA_JWT=$(openssl rand -hex 32)
    BOOKSTACK_KEY="base64:$(openssl rand -base64 32)"
    N8N_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    N8N_ENC=$(openssl rand -hex 32)
    MEILI_KEY=$(openssl rand -hex 32)
    GRAFANA_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    GRAFANA_SECRET=$(openssl rand -hex 32)

    # Patch .env with generated values
    sed -i "s/POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD_HERE/POSTGRES_PASSWORD=${POSTGRES_PASS}/" .env
    sed -i "s/REDIS_PASSWORD=CHANGE_ME_REDIS_PASSWORD_HERE/REDIS_PASSWORD=${REDIS_PASS}/" .env
    sed -i "s/VIKUNJA_JWT_SECRET=CHANGE_ME_JWT_SECRET_HERE/VIKUNJA_JWT_SECRET=${VIKUNJA_JWT}/" .env
    sed -i "s|BOOKSTACK_APP_KEY=base64:CHANGE_ME_BOOKSTACK_KEY_HERE|BOOKSTACK_APP_KEY=${BOOKSTACK_KEY}|" .env
    sed -i "s/N8N_BASIC_AUTH_PASSWORD=CHANGE_ME_N8N_PASSWORD_HERE/N8N_BASIC_AUTH_PASSWORD=${N8N_PASS}/" .env
    sed -i "s/N8N_ENCRYPTION_KEY=CHANGE_ME_N8N_ENCRYPTION_KEY_HERE/N8N_ENCRYPTION_KEY=${N8N_ENC}/" .env
    sed -i "s/MEILISEARCH_MASTER_KEY=CHANGE_ME_MEILISEARCH_KEY_HERE/MEILISEARCH_MASTER_KEY=${MEILI_KEY}/" .env
    sed -i "s/GRAFANA_ADMIN_PASSWORD=CHANGE_ME_GRAFANA_PASSWORD_HERE/GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASS}/" .env
    sed -i "s/GRAFANA_SECRET_KEY=CHANGE_ME_GRAFANA_SECRET_HERE/GRAFANA_SECRET_KEY=${GRAFANA_SECRET}/" .env

    success ".env created with auto-generated secrets"

    echo ""
    echo -e "${BOLD}Generated credentials (save these!):${NC}"
    echo -e "  PostgreSQL password : ${YELLOW}${POSTGRES_PASS}${NC}"
    echo -e "  Redis password      : ${YELLOW}${REDIS_PASS}${NC}"
    echo -e "  n8n password        : ${YELLOW}${N8N_PASS}${NC}"
    echo -e "  Grafana password    : ${YELLOW}${GRAFANA_PASS}${NC}"
    echo ""
    warn "All credentials are also stored in .env — do NOT commit this file!"
fi

# ── Domain prompt ─────────────────────────────────────────────────────────────
CURRENT_DOMAIN=$(grep "^BASE_DOMAIN=" .env | cut -d= -f2)
if [[ "$CURRENT_DOMAIN" == "techops.example.com" ]]; then
    echo ""
    read -rp "Enter your base domain (e.g. techops.myserver.com) or press Enter for local mode: " USER_DOMAIN
    if [[ -n "$USER_DOMAIN" ]]; then
        sed -i "s/BASE_DOMAIN=techops.example.com/BASE_DOMAIN=${USER_DOMAIN}/" .env
        success "Domain set to: ${USER_DOMAIN}"
        LOCAL_MODE=false
    else
        info "Using local mode (no domain, no TLS)."
        LOCAL_MODE=true
    fi
else
    LOCAL_MODE=false
fi

# ── Fix script permissions ────────────────────────────────────────────────────
header "Preparing scripts"
chmod +x scripts/*.sh 2>/dev/null || true
success "Script permissions set"

# ── Pull images ───────────────────────────────────────────────────────────────
header "Pulling Docker images"
info "This may take a few minutes on first run..."
docker compose pull
success "All images pulled"

# ── Start services ────────────────────────────────────────────────────────────
header "Starting TechOps Platform"

if [[ "$LOCAL_MODE" == true ]]; then
    info "Starting in local development mode..."
    docker compose -f docker-compose.yml -f docker-compose.local.yml up -d
else
    info "Starting in production mode..."
    docker compose up -d
fi

# ── Health checks ─────────────────────────────────────────────────────────────
header "Waiting for services to become healthy"

wait_for_service() {
    local name=$1
    local url=$2
    local max_attempts=${3:-30}
    local attempt=0

    printf "  Waiting for %-20s" "$name..."
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -sf "$url" &>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        sleep 3
        ((attempt++))
        printf "."
    done
    echo -e " ${YELLOW}timeout${NC} (may still be starting)"
}

if [[ "$LOCAL_MODE" == true ]]; then
    wait_for_service "PostgreSQL" "http://localhost:3000" 20
    wait_for_service "Forgejo"    "http://localhost:3000"
    wait_for_service "Vikunja"    "http://localhost:3456/api/v1/info"
    wait_for_service "BookStack"  "http://localhost:6875"
    wait_for_service "n8n"        "http://localhost:5678/healthz"
    wait_for_service "Grafana"    "http://localhost:3001/api/health"
    wait_for_service "Meilisearch" "http://localhost:7700/health"
fi

# ── Show summary ──────────────────────────────────────────────────────────────
header "TechOps Platform is running!"

DOMAIN=$(grep "^BASE_DOMAIN=" .env | cut -d= -f2)
N8N_PASS_SHOW=$(grep "^N8N_BASIC_AUTH_PASSWORD=" .env | cut -d= -f2)
GRAFANA_PASS_SHOW=$(grep "^GRAFANA_ADMIN_PASSWORD=" .env | cut -d= -f2)

if [[ "$LOCAL_MODE" == true ]]; then
    echo -e "${BOLD}Service URLs (local mode):${NC}"
    echo -e "  🐙 Forgejo (Git)     → ${BLUE}http://localhost:3000${NC}"
    echo -e "  ✅ Vikunja (Tasks)   → ${BLUE}http://localhost:3456${NC}"
    echo -e "  📚 BookStack (Wiki)  → ${BLUE}http://localhost:6875${NC}"
    echo -e "  ⚡ n8n (Automation)  → ${BLUE}http://localhost:5678${NC}  (admin / ${N8N_PASS_SHOW})"
    echo -e "  📊 Grafana           → ${BLUE}http://localhost:3001${NC}  (admin / ${GRAFANA_PASS_SHOW})"
    echo -e "  🔍 Meilisearch       → ${BLUE}http://localhost:7700${NC}"
    echo -e "  📈 Prometheus        → ${BLUE}http://localhost:9090${NC}"
else
    echo -e "${BOLD}Service URLs:${NC}"
    echo -e "  🐙 Forgejo (Git)     → ${BLUE}https://git.${DOMAIN}${NC}"
    echo -e "  ✅ Vikunja (Tasks)   → ${BLUE}https://tasks.${DOMAIN}${NC}"
    echo -e "  📚 BookStack (Wiki)  → ${BLUE}https://wiki.${DOMAIN}${NC}"
    echo -e "  ⚡ n8n (Automation)  → ${BLUE}https://automation.${DOMAIN}${NC}  (admin / ${N8N_PASS_SHOW})"
    echo -e "  📊 Grafana           → ${BLUE}https://grafana.${DOMAIN}${NC}  (admin / ${GRAFANA_PASS_SHOW})"
    echo -e "  🔍 Meilisearch       → ${BLUE}https://search.${DOMAIN}${NC}"
    echo -e "  🔀 Traefik Dashboard → ${BLUE}https://traefik.${DOMAIN}${NC}"
fi

echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  1. Complete Forgejo setup at the URL above (admin account setup on first visit)"
echo -e "  2. Create your first project in Vikunja"
echo -e "  3. Set up your knowledge base in BookStack"
echo -e "  4. Import n8n automation workflows from ./automation/"
echo -e "  5. Review Grafana dashboards (datasources are auto-provisioned)"
echo ""
echo -e "${BOLD}Useful commands:${NC}"
echo -e "  Stop platform    : docker compose down"
echo -e "  View logs        : docker compose logs -f [service]"
echo -e "  Status           : docker compose ps"
echo -e "  Backup           : ./scripts/backup.sh"
echo -e "  Update images    : docker compose pull && docker compose up -d"
echo ""
success "Setup complete. Happy DevOps! 🚀"
