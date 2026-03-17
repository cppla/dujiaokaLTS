#!/bin/sh
set -eu

cd /var/www/html

mkdir -p \
    /run/nginx \
    bootstrap/cache \
    public/uploads \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/testing \
    storage/framework/views \
    storage/logs

if [ -d storage.dist ] && [ -z "$(ls -A storage 2>/dev/null)" ]; then
    cp -a storage.dist/. storage/
fi

if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
fi

if [ "${INSTALL:-true}" = "true" ]; then
    rm -f install.lock
else
    touch install.lock
fi

chown -R www-data:www-data bootstrap/cache public/uploads storage
chmod -R ug+rwx bootstrap/cache public/uploads storage

php artisan package:discover --ansi >/dev/null 2>&1 || true
php artisan config:clear >/dev/null 2>&1 || true
php artisan cache:clear >/dev/null 2>&1 || true

exec /usr/bin/supervisord -c /etc/supervisord.conf