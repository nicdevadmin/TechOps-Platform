#!/bin/bash
# =============================================================================
# TechOps Platform — PostgreSQL Database Initializer
# Runs automatically on first postgres container start via docker-entrypoint.d
# Creates separate databases for each service sharing the PostgreSQL instance
# =============================================================================

set -e

echo "[init-dbs] Creating TechOps service databases..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "techops" <<-EOSQL

    -- Forgejo (Git hosting)
    CREATE DATABASE forgejo
        WITH OWNER = $POSTGRES_USER
        ENCODING = 'UTF8'
        LC_COLLATE = 'en_US.UTF-8'
        LC_CTYPE = 'en_US.UTF-8'
        TEMPLATE = template0;

    -- Vikunja (Task management)
    CREATE DATABASE vikunja
        WITH OWNER = $POSTGRES_USER
        ENCODING = 'UTF8'
        LC_COLLATE = 'en_US.UTF-8'
        LC_CTYPE = 'en_US.UTF-8'
        TEMPLATE = template0;

    -- BookStack (Knowledge wiki)
    CREATE DATABASE bookstack
        WITH OWNER = $POSTGRES_USER
        ENCODING = 'UTF8'
        LC_COLLATE = 'en_US.UTF-8'
        LC_CTYPE = 'en_US.UTF-8'
        TEMPLATE = template0;

    -- n8n (Automation workflows)
    CREATE DATABASE n8n
        WITH OWNER = $POSTGRES_USER
        ENCODING = 'UTF8'
        LC_COLLATE = 'en_US.UTF-8'
        LC_CTYPE = 'en_US.UTF-8'
        TEMPLATE = template0;

    -- Grafana (Dashboards & analytics)
    CREATE DATABASE grafana
        WITH OWNER = $POSTGRES_USER
        ENCODING = 'UTF8'
        LC_COLLATE = 'en_US.UTF-8'
        LC_CTYPE = 'en_US.UTF-8'
        TEMPLATE = template0;

    -- TechOps custom tables (tasks, productivity metrics, HR ops)
    CREATE DATABASE techops_app
        WITH OWNER = $POSTGRES_USER
        ENCODING = 'UTF8'
        LC_COLLATE = 'en_US.UTF-8'
        LC_CTYPE = 'en_US.UTF-8'
        TEMPLATE = template0;

    -- Grant all privileges
    GRANT ALL PRIVILEGES ON DATABASE forgejo TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE vikunja TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE bookstack TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE grafana TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE techops_app TO $POSTGRES_USER;

EOSQL

echo "[init-dbs] ✓ All databases created successfully."
echo "[init-dbs] Databases: forgejo | vikunja | bookstack | n8n | grafana | techops_app"
