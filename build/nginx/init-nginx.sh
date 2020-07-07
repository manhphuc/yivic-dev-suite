#!/bin/bash -e

FILE=/etc/nginx/conf.d/default.conf
if ! [ -f "$FILE" ]; then 
    cp /etc/nginx/conf.d/default.conf.example $FILE
fi

# Nginx
nginx -g 'daemon off;'