# TechOps Platform

> An open-source, self-hosted, Docker-based Technical Operations Platform combining task management, knowledge management, productivity analytics, workflow automation, and AI assistance.

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](docker-compose.yml)
[![Platforms](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL2%20%7C%20NAS-lightgrey)]()

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://git.yourdomain.com/techops/techops-platform.git
cd techops-platform

# 2. Run the setup wizard (generates secrets, starts all services)
chmod +x setup.sh
./setup.sh

# --- OR manually ---
cp .env.example .env          # Edit .env with your domain + credentials
docker compose up -d          # Production (with TLS via Traefik)

# Local development (no domain, plain HTTP)
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d
```

That's it. The setup script generates all cryptographic secrets, creates databases, and starts every service automatically.

---

## Platform Services

| Service | Role | Local URL | Subdomain |
|---------|------|-----------|-----------|
| **Forgejo** | Git repository hosting | :3000 | git.yourdomain.com |
| **Vikunja** | Task & project management | :3456 | tasks.yourdomain.com |
| **BookStack** | Knowledge wiki | :6875 | wiki.yourdomain.com |
| **n8n** | Workflow automation | :5678 | automation.yourdomain.com |
| **Grafana** | Dashboards & analytics | :3001 | grafana.yourdomain.com |
| **Meilisearch** | Full-text search | :7700 | search.yourdomain.com |
| **Prometheus** | Metrics collection | :9090 | prometheus.yourdomain.com |
| **Loki** | Log aggregation | :3100 | (internal) |
| **PostgreSQL** | Shared database | :5432 | (internal) |
| **Redis** | Cache & queue | :6379 | (internal) |
| **Traefik** | Reverse proxy + TLS | :80/:443 | traefik.yourdomain.com |

---

## Repository Structure

```
techops-platform/
│
├── docker-compose.yml          # Main production stack
├── docker-compose.local.yml    # Local development overrides
├── .env.example                # Environment template (copy to .env)
├── setup.sh                    # One-click setup wizard
│
├── apps/                       # App-specific configs (future)
│   ├── forgejo/
│   ├── vikunja/
│   ├── bookstack/
│   ├── n8n/
│   └── grafana/
│
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml      # Prometheus scrape config
│   ├── loki/
│   │   ├── loki.yml            # Loki config
│   │   └── promtail.yml        # Log shipper config
│   └── grafana/
│       ├── dashboards/         # Pre-built Grafana dashboards
│       └── provisioning/       # Auto-provision datasources + dashboards
│
├── scripts/
│   ├── init-dbs.sh             # PostgreSQL multi-DB initializer
│   ├── backup.sh               # Full backup script
│   └── restore.sh              # Restore from backup
│
├── automation/
│   └── scripts/                # Python/Bash automation scripts (n8n)
│
├── knowledgebase/              # Markdown knowledge base (Git-versioned)
│
├── infrastructure/
│   ├── compose/                # Additional compose overlays
│   ├── terraform/              # Infrastructure as code (future)
│   └── kubernetes/             # Helm charts (Phase 7)
│
├── docs/
│   ├── architecture/
│   ├── deployment/
│   ├── api/
│   └── troubleshooting/
│
└── .github/
    ├── workflows/              # CI/CD pipelines
    └── ISSUE_TEMPLATE/         # GitHub/Forgejo issue templates
```

---

## Design Principles

1. **Simplicity first** — `git clone` + `docker compose up` is all it takes
2. **Offline first** — works without internet after initial pull
3. **Self-hosted first** — your data stays on your infrastructure
4. **Open source only** — every component is MIT/Apache 2.0/GPL
5. **Docker first** — no complex system dependencies
6. **Git driven** — all config and knowledge is version-controlled
7. **Markdown first** — human-readable, portable, future-proof
8. **API first** — every service exposes REST APIs for automation
9. **Modular** — add/remove services independently
10. **Automation first** — repetitive work becomes n8n workflows
11. **AI augmented** — Ollama + RAG (Phase 4)
12. **Vendor independent** — zero proprietary lock-in

---

## Target Environments

| Environment | Config | Notes |
|------------|--------|-------|
| Local workstation | `docker-compose.local.yml` overlay | Plain HTTP, no domain needed |
| Home lab / NAS | `docker-compose.yml` | Use local domain via DNS |
| VPS / Cloud VM | `docker-compose.yml` | Full TLS via Let's Encrypt |
| Kubernetes | `infrastructure/kubernetes/` | Phase 7 — Helm charts |

Minimum hardware for MVP: **2 vCPU, 4 GB RAM, 40 GB disk**
Recommended: **4 vCPU, 8 GB RAM, 100 GB SSD**

---

## Common Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View all service logs
docker compose logs -f

# View logs for a specific service
docker compose logs -f vikunja

# Check service health
docker compose ps

# Restart a single service
docker compose restart n8n

# Pull latest images (then restart)
docker compose pull && docker compose up -d

# Full backup
./scripts/backup.sh full

# Database backup only
./scripts/backup.sh db-only

# Scale a service (e.g. add n8n workers)
docker compose up -d --scale n8n=2
```

---

## Environment Variables

All configuration lives in `.env`. See [`.env.example`](.env.example) for the full reference.

Critical variables:

| Variable | Description |
|----------|-------------|
| `BASE_DOMAIN` | Your base domain (all services are subdomains) |
| `POSTGRES_PASSWORD` | Shared PostgreSQL password |
| `REDIS_PASSWORD` | Redis password |
| `ACME_EMAIL` | Email for Let's Encrypt TLS |
| `TIMEZONE` | Your timezone (e.g. `Asia/Kolkata`) |

The `setup.sh` script auto-generates all secret values. For manual setup, generate secrets with:

```bash
openssl rand -hex 32    # For JWT secrets, encryption keys
openssl rand -base64 24 # For passwords
```

---

## Backup & Recovery

```bash
# Full backup (PostgreSQL + volumes + configs + knowledgebase)
./scripts/backup.sh full

# Backups are stored in ./backups/ with 30-day retention
# Structure: backups/{postgres,volumes,configs,knowledgebase}/TIMESTAMP/
```

To restore from backup, see [`docs/operations/restore.md`](docs/operations/restore.md).

---

## Roadmap

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | MVP — Core stack (this release) | 🟡 In progress |
| 2 | Knowledge platform enhancements | ⬜ Planned |
| 3 | Automation layer | ⬜ Planned |
| 4 | AI integration (Ollama + RAG) | ⬜ Planned |
| 5 | Open-source release | ⬜ Planned |
| 6 | Multi-user / team support | ⬜ Planned |
| 7 | Kubernetes / Helm | ⬜ Planned |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). All contributions welcome.

---

## License

[Apache 2.0](LICENSE) — free to use, modify, and distribute. Patent protection included.
