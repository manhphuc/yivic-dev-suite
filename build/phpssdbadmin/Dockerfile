FROM richarvey/nginx-php-fpm:latest
LABEL maintainer="Leonard Buskin <leonardbuskin@gmail.com>"

ARG VERSION=${VERSION:-master}

RUN apk add --no-cache --virtual .build-deps curl tar \
    && mkdir -p /var/www/html \
    && curl -Lk "https://github.com/ssdb/phpssdbadmin/archive/${VERSION}.tar.gz" | \
       tar -xz -C /var/www/html --strip-components=1 \
    && apk del .build-deps

EXPOSE 443 80

COPY ./configs/nginx-site.conf /var/www/html/conf/nginx/
COPY ./docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["/start.sh"]