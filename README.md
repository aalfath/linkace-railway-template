[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/linkace?utm_medium=integration&utm_source=button&utm_campaign=linkace)

# LinkAce on Railway

One-click [LinkAce](https://www.linkace.org) for [Railway](https://railway.com): a self-hosted bookmark archive with tags, lists, notes, link monitoring and the Wayback Machine.

- **LinkAce v2.6.4**, from the official image `linkace/linkace:v2.6.4`, pinned by digest in the [`Dockerfile`](Dockerfile).
- Licence of LinkAce: GPL-3.0 ([Kovah/LinkAce](https://github.com/Kovah/LinkAce)). This repo only packages it.

## What the template deploys

| Service | Source | What it does |
|---|---|---|
| **LinkAce** | this repo (`Dockerfile`) | Web app (Caddy + PHP-FPM) and Laravel's scheduler (queue for imports, link checks every two hours). Public HTTPS domain, health check `/_health`. Volume on `/app/storage` (logs, imports, files). |
| **Postgres** | Railway's Postgres | Database: links, lists, tags, notes, users and settings. Own volume. |
| **Redis** | Railway's Redis | Cache and login sessions. |

On every start the LinkAce service waits for Postgres and Redis, then runs `php artisan migrate --force`, so the tables exist on the first deploy and an update applies its schema changes on its own.

## After the deploy

1. Open the public URL. LinkAce's setup wizard starts.
2. The requirements check should be all green. Click **Continue**: the database is already set up, so the wizard goes straight to the account step.
3. Create the first admin (user name, email, password). That account manages users and system settings.

## Variables

All are set by the template; nothing to fill in.

| Variable | Default | Notes |
|---|---|---|
| `APP_KEY` | `${{secret(32)}}` | Laravel encryption key. Keep it: changing it logs everyone out and breaks stored secrets. |
| `APP_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public address used in links and emails. Change it if you add a custom domain. |
| `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` | references to the Postgres service | Private network. |
| `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` | references to the Redis service | Private network. |

`TRUSTED_HOSTS` is derived from `APP_URL` at start (plus Railway's health-check host), so after you add a custom domain, update `APP_URL` and redeploy.

Fixed settings (Postgres driver, Redis cache and sessions, database search, production mode, trusted proxy) are `ENV` lines in the `Dockerfile`; a service variable with the same name overrides them.

Optional, add them on the LinkAce service if you want them:

- **Email** (password resets, invitations, link-check reports): `MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_ENCRYPTION`, `MAIL_FROM_ADDRESS`.
- **LinkAce's own backups**: off by default (`BACKUP_ENABLED=false`), because they would zip the app into the same volume every night. Use Railway's Postgres and volume backups, or set `BACKUP_ENABLED=true` with an S3 disk as in the [LinkAce docs](https://www.linkace.org/docs/v2/configuration/backups/).
- **Single sign-on** (OIDC, Keycloak, Authentik …): see the [LinkAce SSO docs](https://www.linkace.org/docs/v2/configuration/sso-oauth-oidc/).

## Resources

LinkAce runs in the 0.5 GB RAM a Railway Free or Trial service gets: PHP-FPM is capped at 4 workers, and the container used about 120 MB idle in our tests. If the web server, PHP-FPM or the scheduler fails for good, the container exits with a non-zero code so Railway's `ON_FAILURE` restart policy brings it back.

## Updates

Railway tells everyone who deployed this template when this repo's `main` branch changes ("update available" in the project). An update rebuilds the LinkAce service from the new `Dockerfile`; your Postgres data and the volume stay. Read [`CHANGELOG.md`](CHANGELOG.md) before you apply one: breaking changes are listed first.

## Repo layout

- `Dockerfile`: the pinned official image plus the small Railway wrapper.
- `railway/start.sh`: checks variables, prepares the volume, waits for Postgres and Redis, runs migrations, starts supervisord.
- `railway/supervisord.ini`: Caddy, PHP-FPM and the scheduler; exits the container if one of them fails for good.
- `railway/Caddyfile`: listens on `PORT`, trusts Railway's proxy, skips the wizard's database form.
- `railway/php-fpm-railway.conf`: worker limits for small services.
