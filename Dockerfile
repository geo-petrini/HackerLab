FROM php:7.4-apache

ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Zurich \
    MYSQL_ROOT_PASSWORD=root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       default-mysql-server libzip-dev zip unzip libpng-dev libonig-dev zlib1g-dev libxml2-dev  \
    && docker-php-ext-install pdo pdo_mysql mysqli mbstring exif bcmath zip gd \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy project files
COPY . /var/www/html

# Prepare MySQL runtime dirs and set permissions
RUN mkdir -p /var/run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/lib/mysql || true \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html || true

# Add entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]