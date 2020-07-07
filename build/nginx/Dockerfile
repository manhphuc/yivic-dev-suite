ARG NGINX_VERSION

FROM nginx:${NGINX_VERSION}-alpine

WORKDIR /var/www/html
COPY ./init-nginx.sh /var/init-nginx.sh
RUN chmod +x /var/init-nginx.sh
ENTRYPOINT ["/bin/sh", "/var/init-nginx.sh"]

# Force logs to files
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log