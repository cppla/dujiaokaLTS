FROM php:7.4-fpm-alpine

LABEL maintainer="AI"

ARG TZ=Asia/Shanghai

ENV TZ=${TZ} \
    APP_DIR=/var/www/html \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    INSTALL=false

RUN set -eux; \
    apk add --no-cache \
        bash \
        curl \
        nginx \
        supervisor \
        tzdata \
        icu-libs \
        libzip \
        freetype \
        libpng \
        libjpeg-turbo \
        libwebp \
        libxml2 \
        mariadb-connector-c; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libzip-dev \
        freetype-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        libwebp-dev \
        libxml2-dev \
        mariadb-connector-c-dev; \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" bcmath exif gd intl mysqli opcache pcntl pdo_mysql zip; \
    pecl install redis; \
    docker-php-ext-enable redis; \
    apk del .build-deps; \
    rm -rf /tmp/pear

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN set -eux; \
    composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction --no-scripts; \
    mv storage storage.dist; \
    mkdir -p storage public/uploads bootstrap/cache /run/nginx; \
    sed -i "s/protected \$proxies;/protected \$proxies = '**';/" app/Http/Middleware/TrustProxies.php; \
    printf '%s\n' \
        'user nginx;' \
        'worker_processes auto;' \
        'pid /run/nginx/nginx.pid;' \
        '' \
        'events {' \
        '    worker_connections 1024;' \
        '}' \
        '' \
        'http {' \
        '    include /etc/nginx/mime.types;' \
        '    default_type application/octet-stream;' \
        '' \
        '    sendfile on;' \
        '    tcp_nopush on;' \
        '    tcp_nodelay on;' \
        '    keepalive_timeout 65;' \
        '    server_tokens off;' \
        '' \
        '    access_log /dev/stdout;' \
        '    error_log /dev/stderr warn;' \
        '' \
        '    include /etc/nginx/conf.d/*.conf;' \
        '}' > /etc/nginx/nginx.conf; \
    mkdir -p /etc/nginx/conf.d; \
    printf '%s\n' \
        'server {' \
        '    listen 80;' \
        '    server_name _;' \
        '    root /var/www/html/public;' \
        '    index index.php index.html;' \
        '    client_max_body_size 50m;' \
        '' \
        '    location / {' \
        '        try_files $uri $uri/ /index.php?$query_string;' \
        '    }' \
        '' \
        '    location ~ \.php$ {' \
        '        include fastcgi_params;' \
        '        fastcgi_pass 127.0.0.1:9000;' \
        '        fastcgi_index index.php;' \
        '        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;' \
        '        fastcgi_param DOCUMENT_ROOT $realpath_root;' \
        '        fastcgi_read_timeout 300;' \
        '    }' \
        '' \
        '    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|webp|svg|woff|woff2|ttf)$ {' \
        '        expires 30d;' \
        '        access_log off;' \
        '        add_header Cache-Control "public";' \
        '    }' \
        '' \
        '    location ~ /\. {' \
        '        deny all;' \
        '    }' \
        '}' > /etc/nginx/conf.d/default.conf; \
    printf '%s\n' \
        '[supervisord]' \
        'nodaemon=true' \
        'logfile=/dev/null' \
        'pidfile=/run/supervisord.pid' \
        '' \
        '[program:php-fpm]' \
        'command=/usr/local/sbin/php-fpm -F' \
        'priority=10' \
        'autostart=true' \
        'autorestart=true' \
        'stdout_logfile=/dev/stdout' \
        'stdout_logfile_maxbytes=0' \
        'stderr_logfile=/dev/stderr' \
        'stderr_logfile_maxbytes=0' \
        '' \
        '[program:nginx]' \
        'command=/usr/sbin/nginx -g "daemon off;"' \
        'priority=20' \
        'autostart=true' \
        'autorestart=true' \
        'stdout_logfile=/dev/stdout' \
        'stdout_logfile_maxbytes=0' \
        'stderr_logfile=/dev/stderr' \
        'stderr_logfile_maxbytes=0' \
        '' \
        '[program:queue-worker]' \
        'command=/usr/local/bin/worker.sh' \
        'priority=30' \
        'autostart=true' \
        'autorestart=true' \
        'startsecs=0' \
        'stdout_logfile=/dev/stdout' \
        'stdout_logfile_maxbytes=0' \
        'stderr_logfile=/dev/stderr' \
        'stderr_logfile_maxbytes=0' > /etc/supervisord.conf; \
    printf '%s\n' \
        'memory_limit=512M' \
        'post_max_size=50M' \
        'upload_max_filesize=50M' \
        'max_execution_time=300' \
        'max_input_vars=3000' \
        'opcache.enable=1' \
        'opcache.enable_cli=1' \
        'opcache.validate_timestamps=1' \
        'opcache.max_accelerated_files=20000' \
        'opcache.memory_consumption=192' > /usr/local/etc/php/conf.d/dujiaoka.ini; \
    printf '%s\n' \
        '#!/bin/sh' \
        'set -eu' \
        '' \
        'cd /var/www/html' \
        '' \
        'while [ ! -f .env ] || [ ! -f install.lock ]; do' \
        '    sleep 5' \
        'done' \
        '' \
        'exec php artisan queue:work --sleep=3 --tries=3 --timeout=90' > /usr/local/bin/worker.sh; \
    printf '%s\n' \
        '#!/bin/sh' \
        'set -eu' \
        '' \
        'cd /var/www/html' \
        '' \
        'mkdir -p \' \
        '    /run/nginx \' \
        '    bootstrap/cache \' \
        '    public/uploads \' \
        '    storage/framework/cache \' \
        '    storage/framework/sessions \' \
        '    storage/framework/testing \' \
        '    storage/framework/views \' \
        '    storage/logs' \
        '' \
        'if [ -d storage.dist ] && [ -z "$(ls -A storage 2>/dev/null)" ]; then' \
        '    cp -a storage.dist/. storage/' \
        'fi' \
        '' \
        'if [ ! -f .env ] && [ -f .env.example ]; then' \
        '    cp .env.example .env' \
        'fi' \
        '' \
        'if [ -n "${ADMIN_HTTPS:-}" ] && [ -f .env ]; then' \
        '    tmp_env="$(mktemp)"' \
        '    if grep -q "^ADMIN_HTTPS=" .env; then' \
        '        sed "s/^ADMIN_HTTPS=.*/ADMIN_HTTPS=${ADMIN_HTTPS}/" .env > "${tmp_env}"' \
        '    else' \
        '        cat .env > "${tmp_env}"' \
        '        printf "\nADMIN_HTTPS=%s\n" "${ADMIN_HTTPS}" >> "${tmp_env}"' \
        '    fi' \
        '    cat "${tmp_env}" > .env' \
        '    rm -f "${tmp_env}"' \
        'fi' \
        '' \
        'if [ -f .env ] && grep -q "^ADMIN_ROUTE_PREFIX={admin_path}$" .env; then' \
        '    tmp_env="$(mktemp)"' \
        '    sed "s/^ADMIN_ROUTE_PREFIX={admin_path}$/ADMIN_ROUTE_PREFIX=admin/" .env > "${tmp_env}"' \
        '    cat "${tmp_env}" > .env' \
        '    rm -f "${tmp_env}"' \
        'fi' \
        '' \
        'if [ "${INSTALL:-true}" = "true" ]; then' \
        '    rm -f install.lock' \
        'else' \
        '    touch install.lock' \
        'fi' \
        '' \
        'chown -R www-data:www-data bootstrap/cache public/uploads storage' \
        'chmod -R ug+rwx bootstrap/cache public/uploads storage' \
        '' \
        'php artisan package:discover --ansi >/dev/null 2>&1 || true' \
        'php artisan config:clear >/dev/null 2>&1 || true' \
        'php artisan cache:clear >/dev/null 2>&1 || true' \
        '' \
        'exec /usr/bin/supervisord -c /etc/supervisord.conf' > /usr/local/bin/docker-entrypoint.sh; \
    chmod +x /usr/local/bin/worker.sh /usr/local/bin/docker-entrypoint.sh; \
    chown -R www-data:www-data /var/www/html

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]