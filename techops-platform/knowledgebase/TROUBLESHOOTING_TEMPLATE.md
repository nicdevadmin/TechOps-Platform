---
# =============================================================================
# TechOps Platform — Troubleshooting Note Template
# Copy this file, fill in the fields, commit to knowledgebase/
# =============================================================================

id: TSH-0001
title: "[Service] — Brief description of the problem"
date: 2024-01-01
author: your-name
category: AWS | Linux | Windows | Networking | Docker | Database | Security
severity: Critical | High | Medium | Low
status: Resolved | Open | Investigating
tags: [docker, postgres, timeout, production]

---

## Problem

<!-- What went wrong? One clear sentence. -->

## Symptoms

<!-- Bullet list of observable symptoms -->
- Error message: `...`
- Affected service: ...
- Users impacted: ...
- Time of occurrence: ...

## Environment

- OS: Ubuntu 24.04 LTS
- Docker version: 27.x
- Service version: ...
- Host: production / home-lab / workstation

## Impact

- Severity: High
- Downtime: ~15 minutes
- Services affected: Vikunja, n8n
- Users affected: All

## Root Cause

<!-- What actually caused this? Be specific. -->

## Resolution

### Steps taken

1. First step
2. Second step
3. Third step

### Commands used

```bash
# Command 1 — what it does
docker compose restart postgres

# Command 2
docker compose logs -f postgres --since 30m
```

### Configuration changes

```yaml
# What was changed in which file
```

## Logs

```
Paste relevant log lines here
```

## Screenshots

<!-- Reference screenshot files if stored in knowledgebase/screenshots/ -->
- `screenshots/TSH-0001-error.png`

## Related Incidents

- TSH-0000 — Previous related issue

## Automation Opportunities

<!-- Could this be detected/prevented automatically? -->
- [ ] Add Prometheus alert rule for this condition
- [ ] Add n8n workflow to auto-restart service
- [ ] Add health check to docker-compose.yml

## Preventive Actions

- [ ] Action 1
- [ ] Action 2

## References

- [Official docs](https://docs.example.com/...)
- [Stack Overflow](https://stackoverflow.com/...)
- [GitHub issue](https://github.com/...)
