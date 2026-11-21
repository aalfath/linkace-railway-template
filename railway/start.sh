#!/bin/sh
# Railway wrapper for the official LinkAce image.
set -eu

STORAGE=/app/storage

if [ -z "${APP_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export APP_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

# LinkAce only answers hosts under APP_URL (Laravel TrustHosts). Also allow
# Railway's health-check probe, which sends Host: healthcheck.railway.app.
if [ -z "${TRUSTED_HOSTS:-}" ] && [ -n "${APP_URL:-}" ]; then
  app_host=$(printf '%s' "$APP_URL" | sed -E 's#^[a-zA-Z]+://##; s#[/:].*$##')
  app_host_re=$(printf '%s' "$app_host" | sed 's/[].[^$*+?(){}|\\]/\\&/g')
  export TRUSTED_HOSTS="^(.+\\.)?${app_host_re}\$,^healthcheck\\.railway\\.app\$"
fi

for v in APP_KEY DB_HOST DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST; do
  eval "val=\${$v:-}"
  if [ -z "$val" ]; then
    echo "ERROR: $v is not set. The Railway template sets it; add it on the LinkAce service." >&2
    exit 1
  fi
done
if [ "$APP_KEY" = "someRandomStringWith32Characters" ]; then
  echo "ERROR: APP_KEY still has LinkAce's sample value; set a random 32-character key." >&2
  exit 1
fi

# ---- Volume: /app/storage (logs, sessions fallback, imports, backups) -------
# A fresh Railway volume is empty and owned by root: rebuild the tree upstream ships.
mkdir -p "$STORAGE/app/public" "$STORAGE/app/backups" "$STORAGE/app/backup-temp" "$STORAGE/app/temp" \
  "$STORAGE/framework/cache/data" "$STORAGE/framework/sessions" "$STORAGE/framework/views" \
  "$STORAGE/framework/testing" "$STORAGE/logs"
chown -R www-data:www-data "$STORAGE"

as_www() { su -p -s /bin/sh www-data -c "$*"; }

# ---- Wait for Postgres and Redis, then upgrade the schema if set up ---------
# exit 0: database reachable and LinkAce tables exist; 3: reachable, empty (first run)
i=0
while :; do
  rc=0
  as_www "cd /app && php /railway/db-state.php" || rc=$?
  [ "$rc" -eq 0 ] || [ "$rc" -eq 3 ] && break
  i=$((i + 1))
  if [ "$i" -ge 60 ]; then
    echo "ERROR: database or Redis not reachable after 5 minutes." >&2
    exit 1
  fi
  echo "Waiting for Postgres and Redis ($i)..."
  sleep 5
done

# Create or upgrade the schema (LinkAce and settings migrations). On a fresh
# database this replaces the wizard's database step, so the wizard only asks
# for the first admin account.
[ "$rc" -eq 3 ] && echo "LinkAce: empty database, creating tables"
as_www "cd /app && php artisan migrate --force --no-interaction"
as_www "cd /app && php artisan view:clear >/dev/null 2>&1 || true"

echo "LinkAce: public URL ${APP_URL:-unset}, listening on ${PORT}"
rm -f /tmp/linkace-fatal
/usr/bin/supervisord -c /railway/supervisord.ini &
SPID=$!
trap 'kill -TERM "$SPID" 2>/dev/null; wait "$SPID"; exit 0' TERM INT
wait "$SPID" || true
echo "LinkAce: supervisord stopped unexpectedly; exiting so Railway restarts the service." >&2
exit 1
