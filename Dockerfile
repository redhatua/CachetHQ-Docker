FROM nginx:1.21-alpine

EXPOSE 8000
CMD ["/sbin/entrypoint.sh"]

ARG cachet_ver
ARG archive_url

ENV cachet_ver ${cachet_ver:-2.4}
ENV archive_url ${archive_url:-https://github.com/cachethq/Cachet/archive/${cachet_ver}.tar.gz}

ENV COMPOSER_VERSION 1.9.0

RUN apk add --no-cache --update \
    mysql-client \
    php7 \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-fileinfo \
    php7-fpm \
    php7-gd \
    php7-iconv \
    php7-intl \
    php7-json \
    php7-mbstring \
    php7-mysqli \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-pdo_pgsql \
    php7-pecl-apcu \
    php7-pgsql \
    php7-phar \
    php7-session \
    php7-simplexml \
    php7-soap \
    php7-sqlite3 \
    php7-tokenizer \
    php7-xml \
    php7-xmlreader \
    php7-xmlwriter \
    php7-zip \
    php7-zlib \
    postfix \
    postgresql \
    postgresql-client \
    sqlite \
    sudo \
    supervisor \
    wget sqlite git curl bash grep

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/php7/error.log && \
    ln -sf /dev/stderr /var/log/php7/error.log

RUN adduser -S -s /bin/bash -u 1001 -G root www-data

RUN echo "www-data	ALL=(ALL:ALL)	NOPASSWD:SETENV:	/usr/sbin/postfix" >> /etc/sudoers

RUN touch /var/run/nginx.pid && \
    chown -R www-data:root /var/run/nginx.pid

RUN chown -R www-data:root /etc/php7/php-fpm.d

RUN mkdir -p /var/www/html && \
    mkdir -p /usr/share/nginx/cache && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/lib/nginx && \
    chown -R www-data:root /var/www /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx/

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html/
USER 1001

RUN wget ${archive_url} && \
    tar xzf ${cachet_ver}.tar.gz --strip-components=1 && \
    chown -R www-data:root /var/www/html && \
    rm -r ${cachet_ver}.tar.gz && \
    rm -f /var/www/html/composer.lock && \
    php /usr/local/bin/composer install -o --no-plugins && \
    rm -rf bootstrap/cache/*

COPY conf/php-fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx-site.conf /etc/nginx/conf.d/default.conf
COPY conf/.env.docker /var/www/html/.env
COPY entrypoint.sh /sbin/entrypoint.sh

USER root
RUN chmod g+rwx /var/run/nginx.pid && \
    chmod -R g+rw /var/www /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx/ /etc/php7/php-fpm.d storage
USER 1001
