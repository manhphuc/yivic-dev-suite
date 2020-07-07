FROM php:7-fpm-alpine
LABEL maintainer="Leonard Buskin <leonardbuskin@gmail.com>"

ARG VERSION=${VERSION:-master}

ENV FPM_CONF /usr/local/etc/php-fpm.d/www.conf
ENV PHP_VARS /usr/local/etc/php/conf.d/docker-vars.ini

RUN apk add --no-cache --virtual .build-deps \
        curl tar libmcrypt-dev libpng-dev openssl-dev freetype-dev libjpeg-turbo-dev \
        autoconf gcc g++ make \
    && mkdir -p /var/www/html \
    && curl -Lk "https://github.com/ssdb/phpssdbadmin/archive/${VERSION}.tar.gz" | \
       tar -xz -C /var/www/html --strip-components=1 \
    && apk add --no-cache --virtual .rundeps \
        bash libmcrypt libpng openssl freetype libjpeg-turbo \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gd \
    # && docker-php-ext-enable gd mcrypt openssl \
    && docker-php-source delete \
    && apk del .build-deps

# TODO: Redirect logs to stdout/stderr
RUN echo "cgi.fix_pathinfo=0" > ${PHP_VARS} &&\
    echo "upload_max_filesize = 100M"  >> ${PHP_VARS} &&\
    echo "post_max_size = 100M"  >> ${PHP_VARS} &&\
    echo "variables_order = \"EGPCS\""  >> ${PHP_VARS} && \
    echo "memory_limit = 128M"  >> ${PHP_VARS} && \
    sed -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        -i ${FPM_CONF}

COPY ./docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9000
CMD ["/usr/local/sbin/php-fpm", "--nodaemonize", "--fpm-config", "/usr/local/etc/php-fpm.d/www.conf"]
