# composer dependencies

FROM composer AS composer-build

WORKDIR /var/www/html

COPY composer.lock composer.json /var/www/html/

RUN mkdir -p /var/www/html/database/{factories,seeds} 

RUN composer install --no-dev --prefer-dist --no-scripts --no-autoloader --no-progress --ignore-platform-reqs

# npm dependencies
FROM node:22-alpine AS npm-build

WORKDIR /var/www/html

# COPY package.json package-lock.json webpack.mix.js /var/www/html/
COPY package.json package-lock.json /var/www/html/

COPY resources /var/www/html/resources/

COPY public /var/www/html/public/

RUN npm ci
RUN npm run production

# actual production image
FROM php:8.3-fpm

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd

RUN pecl install redis

RUN docker-php-ext-enable redis

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY --chown=www-data --from=composer-build /var/www/html/vendor/ /var/www/html/vendor/

COPY --chown=www-data --from=npm-build /var/www/html/public/ /var/www/html/public/

COPY --chown=www-data . /var/www/html




