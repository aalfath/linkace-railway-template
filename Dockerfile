# LinkAce for Railway: web app (Caddy + PHP-FPM) and Laravel scheduler in one container.
# Official image, pinned by version and digest. Bump both together and add a CHANGELOG.md entry.
FROM docker.io/linkace/linkace:v2.6.4@sha256:11c8c04833d719e129738cdc2be5b98c85591cae5e6a2085b8e1fc393d3f9a39

# Fixed settings for this template. A variable set on the Railway service wins.
# They live here (not only in start.sh) so `railway ssh` + artisan sees them too.
ENV PORT=8080 \
    APP_ENV=production \
    APP_DEBUG=false \
    TRUSTED_PROXIES=* \
    DB_CONNECTION=pgsql \
    DB_PORT=5432 \
    CACHE_DRIVER=redis \
    SESSION_DRIVER=redis \
    QUEUE_CONNECTION=database \
    APP_SEARCH_DRIVER=database \
    BACKUP_ENABLED=false \
    CADDY_PHP_HOST=127.0.0.1 \
    GOMAXPROCS=2

USER root
COPY railway/ /railway/
# - at most 4 PHP-FPM workers and GOMAXPROCS=2 for Caddy, so it fits a 0.5 GB service
# - LinkAce's own daily backup is off (BACKUP_ENABLED=false): it would zip the app
#   into the same volume every night; use Railway's volume and Postgres backups
# - our Caddyfile trusts Railway's edge so links and assets stay https
# - .env holds no settings: everything comes from Railway variables
#   (the stock .env points at SQLite and would hide a missing variable)
RUN chmod 755 /railway/start.sh /railway/fatal-listener.sh \
    && chmod 644 /railway/db-state.php /railway/supervisord.ini /railway/Caddyfile /railway/php-fpm-railway.conf \
    && cp /railway/Caddyfile /etc/caddy/Caddyfile \
    && cp /railway/php-fpm-railway.conf /usr/local/etc/php-fpm.d/zz-railway.conf \
    && printf '# LinkAce settings come from Railway service variables.\n' > /app/.env \
    && chown www-data:www-data /app/.env

# start.sh runs as root only to prepare the /app/storage volume, then every
# process runs as www-data under supervisord. Any process that keeps failing
# stops the container with a non-zero exit so Railway restarts it.
ENTRYPOINT ["/railway/start.sh"]
