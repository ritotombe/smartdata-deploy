FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
    git curl unzip openssl libpng-dev libonig-dev libxml2-dev libzip-dev libsqlite3-dev sqlite3 \
    && docker-php-ext-install pdo_mysql pdo_sqlite mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /opt/bundle
COPY app.enc /opt/bundle/app.enc

RUN printf '#!/bin/sh\n\
set -e\n\
if [ ! -f /var/www/html/artisan ]; then\n\
  mkdir -p /var/www/html\n\
  openssl enc -d -aes-256-cbc -pbkdf2 -in /opt/bundle/app.enc -out /tmp/app.tar.gz -pass env:APP_BUNDLE_PASS\n\
  tar -xzf /tmp/app.tar.gz -C /var/www/html\n\
  rm -f /tmp/app.tar.gz\n\
  cd /var/www/html\n\
  rm -f bootstrap/cache/*.php\n\
  composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs\n\
  cp .env.example .env\n\
  mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache/data storage/logs bootstrap/cache\n\
  chmod -R 777 storage bootstrap/cache database public\n\
  chmod 666 database/smartdata.sqlite .env\n\
fi\n\
cd /var/www/html\n\
export APP_NAME=${APP_NAME:-SmartData}\n\
export APP_ENV=${APP_ENV:-production}\n\
export APP_DEBUG=${APP_DEBUG:-false}\n\
export APP_KEY=${APP_KEY:-base64:8yX6kZ7p3mR9qL2wV4nB1cT5jH0gF8dS6aE4uI2oP0k=}\n\
export LOG_CHANNEL=${LOG_CHANNEL:-stderr}\n\
export DB_CONNECTION=${DB_CONNECTION:-sqlite}\n\
export DB_DATABASE=${DB_DATABASE:-/var/www/html/database/smartdata.sqlite}\n\
export SESSION_DRIVER=${SESSION_DRIVER:-file}\n\
export CACHE_DRIVER=${CACHE_DRIVER:-file}\n\
php artisan storage:link --force 2>/dev/null || true\n\
php artisan migrate --force\n\
exec php -S 0.0.0.0:${PORT:-8000} -t public\n' > /usr/local/bin/start-container.sh && chmod +x /usr/local/bin/start-container.sh

EXPOSE 8000
CMD ["/usr/local/bin/start-container.sh"]
