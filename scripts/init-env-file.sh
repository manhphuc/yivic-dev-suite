#!/bin/bash -e
echo "----------------------------------------"
echo " PHP Local development with Nginx setup "
echo "----------------------------------------"
echo ""

echo "Init .env file ----"

CURRENT_DIR="$PWD"

ENV_FILE=$CURRENT_DIR/.env
if ! [ -f "$ENV_FILE" ]; then
    cp $ENV_FILE.example $ENV_FILE
fi