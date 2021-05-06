FROM php:7.4-apache

# wordpress/php7.4/apache/Dockerfile
# persistent dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ghostscript \
    ; \
    rm -rf /var/lib/apt/lists/*

# install the PHP extensions we need
RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg-dev \
    libmagickwand-dev \
    libpng-dev \
    libzip-dev \
    ; \
    \
    docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    ; \
    docker-php-ext-install -j "$(nproc)" \
    bcmath \
    exif \
    gd \
    mysqli \
    zip \
    ; \
    pecl install imagick-3.4.4; \
    docker-php-ext-enable imagick; \
    rm -r /tmp/pear; \
    \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
RUN set -eux; \
    docker-php-ext-enable opcache
COPY ./config/opcache-recommended.ini /usr/local/etc/php/conf.d/
COPY ./config/error-logging.ini /usr/local/etc/php/conf.d/
COPY ./config/remoteip.conf /etc/apache2/conf-available/


RUN set -eux; \
    a2enmod rewrite expires; \
    \
    a2enmod remoteip; \
    a2enconf remoteip; \
    find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +

VOLUME /var/www/html

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/conf.d/php.ini

COPY ./src /var/www/html