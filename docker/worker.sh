#!/bin/sh
set -eu

cd /var/www/html

while [ ! -f .env ] || [ ! -f install.lock ]; do
    sleep 5
done

exec php artisan queue:work --sleep=3 --tries=3 --timeout=90