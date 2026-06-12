#!/usr/bin/env bash
# =============================================================================
# TechOps Platform — Backup Script
# Backs up: PostgreSQL · Redis · Docker volumes · Config files
# Usage: ./scripts/backup.sh [full|incremental]
# Schedule: 0 2 * * * /path/to/techops-platform/scripts/backup.sh >> /var/log/techops-backup.log 2>&1
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_MODE="${1:-full}"
RETENTION_DAYS=30

# Load env
set -a
source "${PROJECT_DIR}/.env"
set +a

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "[$(date '+%H:%M:%S')] ${GREEN}INFO${NC}  $*"; }
warn()    { echo -e "[$(date '+%H:%M:%S')] ${YELLOW}WARN${NC}  $*"; }
error()   { echo -e "[$(date '+%H:%M:%S')] ${RED}ERROR${NC} $*"; }

info "=== TechOps Platform Backup — ${BACKUP_MODE} — ${TIMESTAMP} ==="

mkdir -p "${BACKUP_DIR}"/{postgres,volumes,configs,knowledgebase}

# ── PostgreSQL dump ──────────────────────────────────────────────────────────
backup_postgres() {
    info "Backing up PostgreSQL databases..."
    local DB_BACKUP="${BACKUP_DIR}/postgres/${TIMESTAMP}"
    mkdir -p "$DB_BACKUP"

    local DATABASES=("forgejo" "vikunja" "bookstack" "n8n" "grafana" "techops_app")

    for DB in "${DATABASES[@]}"; do
        info "  Dumping database: ${DB}"
        docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T postgres \
            pg_dump -U "${POSTGRES_USER}" --format=custom --compress=9 "${DB}" \
            > "${DB_BACKUP}/${DB}.dump" \
            && info "  ✓ ${DB}.dump ($(du -sh "${DB_BACKUP}/${DB}.dump" | cut -f1))" \
            || warn "  ✗ Failed to dump ${DB}"
    done

    # Full cluster dump as well
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T postgres \
        pg_dumpall -U "${POSTGRES_USER}" \
        | gzip > "${DB_BACKUP}/pg_dumpall.sql.gz" \
        && info "  ✓ pg_dumpall.sql.gz"

    info "PostgreSQL backup complete → ${DB_BACKUP}"
}

# ── Config backup ─────────────────────────────────────────────────────────────
backup_configs() {
    info "Backing up configuration files..."
    local CFG_BACKUP="${BACKUP_DIR}/configs/${TIMESTAMP}"
    mkdir -p "$CFG_BACKUP"

    cp "${PROJECT_DIR}/docker-compose.yml"       "$CFG_BACKUP/"
    cp "${PROJECT_DIR}/docker-compose.local.yml" "$CFG_BACKUP/" 2>/dev/null || true
    cp "${PROJECT_DIR}/.env"                     "$CFG_BACKUP/.env.backup"
    cp -r "${PROJECT_DIR}/monitoring"            "$CFG_BACKUP/"
    cp -r "${PROJECT_DIR}/scripts"               "$CFG_BACKUP/"

    tar -czf "${BACKUP_DIR}/configs/config_${TIMESTAMP}.tar.gz" -C "$CFG_BACKUP" . \
        && rm -rf "$CFG_BACKUP" \
        && info "✓ Config backup: config_${TIMESTAMP}.tar.gz"
}

# ── Knowledge base backup ─────────────────────────────────────────────────────
backup_knowledgebase() {
    info "Backing up knowledge base (Markdown files)..."
    if [[ -d "${PROJECT_DIR}/knowledgebase" ]]; then
        tar -czf "${BACKUP_DIR}/knowledgebase/kb_${TIMESTAMP}.tar.gz" \
            -C "${PROJECT_DIR}" knowledgebase/ \
            && info "✓ Knowledge base backup: kb_${TIMESTAMP}.tar.gz"
    else
        warn "Knowledge base directory not found, skipping."
    fi
}

# ── Docker volume backup ──────────────────────────────────────────────────────
backup_volumes() {
    info "Backing up Docker volumes..."
    local VOL_BACKUP="${BACKUP_DIR}/volumes"

    local VOLUMES=(
        "techops-platform_forgejo_data"
        "techops-platform_bookstack_data"
        "techops-platform_bookstack_uploads"
        "techops-platform_n8n_data"
        "techops-platform_grafana_data"
        "techops-platform_meilisearch_data"
        "techops-platform_loki_data"
    )

    for VOL in "${VOLUMES[@]}"; do
        if docker volume inspect "$VOL" &>/dev/null; then
            info "  Backing up volume: ${VOL}"
            docker run --rm \
                -v "${VOL}:/data:ro" \
                -v "${VOL_BACKUP}:/backup" \
                alpine \
                tar -czf "/backup/${VOL}_${TIMESTAMP}.tar.gz" -C /data . \
                && info "  ✓ ${VOL}_${TIMESTAMP}.tar.gz" \
                || warn "  ✗ Failed to backup ${VOL}"
        else
            warn "  Volume ${VOL} not found, skipping."
        fi
    done
}

# ── Retention cleanup ─────────────────────────────────────────────────────────
cleanup_old_backups() {
    info "Cleaning up backups older than ${RETENTION_DAYS} days..."
    find "${BACKUP_DIR}" -type f -mtime +"${RETENTION_DAYS}" -delete
    find "${BACKUP_DIR}" -type d -empty -delete 2>/dev/null || true
    info "✓ Cleanup complete"
}

# ── Backup size report ────────────────────────────────────────────────────────
report_size() {
    local TOTAL=$(du -sh "${BACKUP_DIR}" 2>/dev/null | cut -f1)
    info "Total backup directory size: ${TOTAL}"
}

# ── Run backup ────────────────────────────────────────────────────────────────
case "${BACKUP_MODE}" in
    full)
        backup_postgres
        backup_configs
        backup_knowledgebase
        backup_volumes
        cleanup_old_backups
        report_size
        ;;
    db-only)
        backup_postgres
        ;;
    config-only)
        backup_configs
        ;;
    *)
        error "Unknown backup mode: ${BACKUP_MODE}. Use: full | db-only | config-only"
        exit 1
        ;;
esac

info "=== Backup complete: ${TIMESTAMP} ==="
