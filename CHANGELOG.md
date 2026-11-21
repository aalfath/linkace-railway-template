# Changelog

Breaking changes are listed first in each entry.

## 2026-11-21: LinkAce v2.6.3 (first release)

- LinkAce v2.6.3 (`linkace/linkace:v2.6.3@sha256:7fad9fb69b421c7428bab8bc820cfd372df4da5f4ff06e9dd1149d20b3e4abd7`), with PHP 8.5.12 (fixes the PHP RCE of 2026-10-21).
- Railway template: LinkAce web app and scheduler, Railway Postgres and Redis, volume on `/app/storage`, migrations on every start, health check `/_health` (trusted hosts derived from `APP_URL` plus Railway's health-check host).
