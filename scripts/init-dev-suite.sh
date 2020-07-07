#!/bin/bash -e
echo "----------------------------------------"
echo " PHP Local development with Nginx setup "
echo "----------------------------------------"
echo ""

echo "Generate self-signed certs to msdev/etc/ssl ----"
docker pull dpyro/alpine-self-signed
docker run --rm -v $PWD/etc/ssl:/certs -e CA_EXPIRE=10000 -e SSL_EXPIRE=10000 dpyro/alpine-self-signed
echo ""

CURRENT_DIR="$PWD"

DOCKER_COMPOSE_FILE=$CURRENT_DIR/docker-compose.yml
if ! [ -f "$DOCKER_COMPOSE_FILE" ]; then
    cp $DOCKER_COMPOSE_FILE.example $DOCKER_COMPOSE_FILE
fi

if [ -n "$1" ]; then
	DEV_NAMESPACE=$1
else 
	DEV_NAMESPACE=$(grep DEV_NAMESPACE .env | xargs)
	IFS='=' read -ra DEV_NAMESPACE <<< "$DEV_NAMESPACE"
	DEV_NAMESPACE=${DEV_NAMESPACE[1]}
fi

sed -i bak -e "s/{{DEV_NAMESPACE}}/${DEV_NAMESPACE}/g" $CURRENT_DIR/docker-compose.yml

rm $CURRENT_DIR/docker-compose.ymlbak

NGINX_CONF_FILE=$CURRENT_DIR/etc/nginx/default.conf
if ! [ -f "$NGINX_CONF_FILE" ]; then
	cp $NGINX_CONF_FILE.example $NGINX_CONF_FILE
fi

