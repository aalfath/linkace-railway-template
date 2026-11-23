# Changelog

Breaking changes are listed first in each entry.

## 2.6.4 (2026-11-23)

- Breaking changes: none. No new variables.
- Security release: system API tokens always respect their abilities, a password change ends other sessions, other users' private lists and tags can't be used as search filters, and usernames stay unique with SSO. See the [v2.6.4 release notes](https://github.com/Kovah/LinkAce/releases/tag/v2.6.4).
- LinkAce v2.6.3 → **v2.6.4** (`linkace/linkace:v2.6.4@sha256:11c8c04833d719e129738cdc2be5b98c85591cae5e6a2085b8e1fc393d3f9a39`).
- Tested on Railway before merging: the published template was deployed, data was written, the service was switched to this version, and the data and login were still there.

## 2026-11-21: LinkAce v2.6.3 (first release)

- LinkAce v2.6.3 (`linkace/linkace:v2.6.3@sha256:7fad9fb69b421c7428bab8bc820cfd372df4da5f4ff06e9dd1149d20b3e4abd7`), with PHP 8.5.12 (fixes the PHP RCE of 2026-10-21).
- Railway template: LinkAce web app and scheduler, Railway Postgres and Redis, volume on `/app/storage`, migrations on every start, health check `/_health` (trusted hosts derived from `APP_URL` plus Railway's health-check host).
