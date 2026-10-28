FROM php:8.4-fpm-bookworm AS php-extensions

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libonig-dev \
        libpq-dev \
        libzip-dev \
        libxml2-dev \
    && docker-php-ext-install -j"$(nproc)" \
        dom \
        mbstring \
        opcache \
        pdo_pgsql \
        xml \
        zip \
    && rm -rf /var/lib/apt/lists/*

FROM php-extensions AS composer-dependencies

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts \
    --no-progress

COPY . .

RUN composer dump-autoload \
        --no-dev \
        --optimize \
        --classmap-authoritative \
        --no-scripts \
    && php artisan package:discover --ansi

FROM node:22-bookworm-slim AS frontend-assets

WORKDIR /var/www/html

COPY package.json ./
RUN npm install --ignore-scripts --no-audit --no-fund

COPY . .
RUN npm run build

FROM php:8.4-fpm-bookworm AS runtime

ENV APP_ENV=production \
    APP_DEBUG=false \
    SESSION_DRIVER=array

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        gettext-base \
        libonig5 \
        libpq5 \
        libzip4 \
        libxml2 \
        nginx \
        supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p \
        /run/nginx \
        /var/log/supervisor \
        /var/www/html/storage/app/public \
        /var/www/html/storage/framework/cache/data \
        /var/www/html/storage/framework/sessions \
        /var/www/html/storage/framework/views \
        /var/www/html/storage/logs \
        /var/www/html/bootstrap/cache

COPY --from=php-extensions /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=php-extensions /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=composer-dependencies /var/www/html /var/www/html
COPY --from=frontend-assets /var/www/html/public/build /var/www/html/public/build

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/php-production.ini /usr/local/etc/php/conf.d/zz-production.ini
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/entrypoint.sh /usr/local/bin/repforge-entrypoint
COPY docker/healthcheck.sh /usr/local/bin/repforge-healthcheck

RUN chmod +x /usr/local/bin/repforge-entrypoint \
    /usr/local/bin/repforge-healthcheck \
    && ln -sfn /var/www/html/storage/app/public /var/www/html/public/storage \
    && chown -R www-data:www-data \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache

WORKDIR /var/www/html

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["/usr/local/bin/repforge-healthcheck"]

ENTRYPOINT ["/usr/local/bin/repforge-entrypoint"]
