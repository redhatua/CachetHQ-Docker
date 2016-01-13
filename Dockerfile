FROM cachethq/docker:base-5a0320b

MAINTAINER Alt Three <support@alt-three.com>

WORKDIR /var/www/html/

RUN wget https://github.com/cachethq/Cachet/archive/master.tar.gz && \
    tar xzvf master.tar.gz --strip-components=1 && \
    chown -R www-data /var/www/html && \
    rm -r master.tar.gz && \
    php composer.phar install --no-dev -o

COPY docker/entrypoint.sh /sbin/entrypoint.sh

COPY docker/.env.docker /var/www/html/.env

COPY docker/crontab /etc/cron.d/artisan-schedule
RUN chmod 0644 /etc/cron.d/artisan-schedule &&\
    touch /var/log/cron.log &&\
    chown www-data /var/www/html/.env

EXPOSE 8000

CMD ["/sbin/entrypoint.sh"]