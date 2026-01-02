#!/bin/bash
# ==============================================================================
# Auto-start All Python Apps (with Dev/Prod Mode)
# File: scripts/python/autostart-python-apps.sh
# ==============================================================================
# Usage:
#   ./scripts/python/autostart-python-apps.sh         # Production mode
#   ./scripts/python/autostart-python-apps.sh dev     # Development mode (auto-reload)
# ==============================================================================

set -e

# Check mode
MODE=${1:-prod}
WWW_DIR="/var/www/html"
LOG_DIR="/var/log/python"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$MODE" == "dev" ]; then
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Auto-starting Python Apps (DEV MODE)${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}Auto-reload enabled - Code changes reload automatically${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}Auto-starting Python Apps (PRODUCTION MODE)${NC}               ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
fi
echo ""

# Function to detect Python version from nginx config
detect_python_version() {
    local app_name=$1
    local config_file="etc/nginx/sites-enabled/${app_name}.conf"

    if [ -f "$config_file" ]; then
        # Extract $python_version from nginx config
        local version=$(grep 'set $python_version' "$config_file" | sed 's/.*"\(.*\)".*/\1/')
        if [ -n "$version" ]; then
            echo "$version"
        else
            # Default to python311_web if not found
            echo "python311_web"
        fi
    else
        # Default to python311_web if config not found
        echo "python311_web"
    fi
}

# Get all Python containers
PYTHON_CONTAINERS=$(docker ps --filter "name=yivic_dev_suite_python" --format "{{.Names}}")

if [ -z "$PYTHON_CONTAINERS" ]; then
    echo -e "${RED}❌ No Python containers are running!${NC}"
    echo -e "${YELLOW}Start them with: docker-compose up -d${NC}"
    exit 1
fi

echo -e "${BLUE}🐍 Available Python containers:${NC}"
for container in $PYTHON_CONTAINERS; do
    echo -e "   ${GREEN}✓${NC} $container"
done
echo ""

# Stop all existing Python processes in all containers
echo -e "${BLUE}🛑 Stopping existing Python apps in all containers...${NC}"
for container in $PYTHON_CONTAINERS; do
    docker exec $container pkill -f "uvicorn|gunicorn" 2>/dev/null || true
done
sleep 1

# Get list of Python apps
APPS=$(ls -d ../www/*/ 2>/dev/null | xargs -n 1 basename 2>/dev/null || echo "")

if [ -z "$APPS" ]; then
    echo -e "${YELLOW}⚠️  No Python apps found in ../www/${NC}"
    exit 0
fi

STARTED_COUNT=0

# Start each app
for app_name in $APPS; do
    # Skip special directories
    if [[ "$app_name" == "build_dockerfile" ]]; then
        continue
    fi

    # Check if has .py files
    if ! ls ../www/$app_name/*.py >/dev/null 2>&1; then
        continue
    fi

    echo -e "${BLUE}📦 Found: $app_name${NC}"

    # Detect Python version from nginx config
    CONTAINER_NAME=$(detect_python_version "$app_name")
    CONTAINER="yivic_dev_suite_${CONTAINER_NAME}"

    echo -e "${BLUE}   🐍 Python version: ${GREEN}${CONTAINER_NAME}${NC}"

    # Check if container exists and is running
    if ! docker ps | grep -q "$CONTAINER"; then
        echo -e "${RED}   ❌ Container $CONTAINER is not running!${NC}"
        echo -e "${YELLOW}   ⏭️  Skipping...${NC}"
        echo ""
        continue
    fi

    # Detect app type
    APP_TYPE=$(docker exec $CONTAINER bash -c "
        cd /var/www/html/$app_name
        if [ -f 'main.py' ] && grep -q 'FastAPI\|fastapi' main.py 2>/dev/null; then
            echo 'fastapi-main'
        elif [ -f 'app.py' ] && grep -q 'FastAPI\|fastapi' app.py 2>/dev/null; then
            echo 'fastapi-app'
        elif [ -f 'app.py' ] && grep -q 'Flask\|flask' app.py 2>/dev/null; then
            echo 'flask'
        elif [ -f 'manage.py' ]; then
            echo 'django'
        else
            echo 'unknown'
        fi
    ")

    # Dev mode: Add --reload flag
    if [ "$MODE" == "dev" ]; then
        RELOAD_FLAG="--reload"
        RELOAD_TEXT="${YELLOW}(auto-reload)${NC}"
    else
        RELOAD_FLAG=""
        RELOAD_TEXT=""
    fi

    case $APP_TYPE in
        fastapi-main)
            echo -e "${GREEN}   ▶️  Starting FastAPI app: uvicorn main:app $RELOAD_TEXT${NC}"
            docker exec -d $CONTAINER bash -c "cd /var/www/html/$app_name && nohup uvicorn main:app --host 0.0.0.0 --port 8000 $RELOAD_FLAG > /var/log/python/$app_name.log 2>&1 &"
            STARTED_COUNT=$((STARTED_COUNT + 1))
            ;;
        fastapi-app)
            echo -e "${GREEN}   ▶️  Starting FastAPI app: uvicorn app:app $RELOAD_TEXT${NC}"
            docker exec -d $CONTAINER bash -c "cd /var/www/html/$app_name && nohup uvicorn app:app --host 0.0.0.0 --port 8000 $RELOAD_FLAG > /var/log/python/$app_name.log 2>&1 &"
            STARTED_COUNT=$((STARTED_COUNT + 1))
            ;;
        flask)
            echo -e "${GREEN}   ▶️  Starting Flask app: gunicorn app:app $RELOAD_TEXT${NC}"
            if [ "$MODE" == "dev" ]; then
                # Flask dev mode with auto-reload
                docker exec -d $CONTAINER bash -c "cd /var/www/html/$app_name && nohup flask run --host 0.0.0.0 --port 8000 --reload > /var/log/python/$app_name.log 2>&1 &"
            else
                docker exec -d $CONTAINER bash -c "cd /var/www/html/$app_name && nohup gunicorn -w 4 -b 0.0.0.0:8000 app:app > /var/log/python/$app_name.log 2>&1 &"
            fi
            STARTED_COUNT=$((STARTED_COUNT + 1))
            ;;
        django)
            echo -e "${GREEN}   ▶️  Starting Django app $RELOAD_TEXT${NC}"
            if [ "$MODE" == "dev" ]; then
                # Django dev server with auto-reload
                docker exec -d $CONTAINER bash -c "cd /var/www/html/$app_name && nohup python manage.py runserver 0.0.0.0:8000 > /var/log/python/$app_name.log 2>&1 &"
            else
                docker exec -d $CONTAINER bash -c "cd /var/www/html/$app_name && nohup gunicorn \$(ls -d */ | head -1 | sed 's/\///').wsgi:application -w 4 -b 0.0.0.0:8000 > /var/log/python/$app_name.log 2>&1 &"
            fi
            STARTED_COUNT=$((STARTED_COUNT + 1))
            ;;
        *)
            echo -e "${YELLOW}   ⏭️  Skipped (not a recognized Python web app)${NC}"
            ;;
    esac

    echo ""
done

echo -e "${GREEN}✅ Started $STARTED_COUNT Python app(s)${NC}"

# Reload nginx to update IPs
echo ""
echo -e "${BLUE}🔄 Reloading nginx...${NC}"
docker-compose restart nginx_main >/dev/null 2>&1
sleep 2

echo ""
echo -e "${GREEN}✅ Done!${NC}"

if [ "$MODE" == "dev" ]; then
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}DEV MODE ACTIVE${NC}                                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Apps will auto-reload when you edit Python files          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  No need to restart when changing code!                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${BLUE}📊 Check running processes in all containers:${NC}"
for container in $PYTHON_CONTAINERS; do
    PROCESSES=$(docker exec $container ps aux | grep -E "uvicorn|gunicorn|flask|manage.py" | grep -v grep || echo "")
    if [ -n "$PROCESSES" ]; then
        echo -e "${GREEN}▶ $container:${NC}"
        echo "$PROCESSES"
    fi
done

echo ""
echo -e "${BLUE}📜 View logs:${NC}"
echo -e "   docker exec <container> tail -f /var/log/python/<app-name>.log"

if [ "$MODE" == "dev" ]; then
    echo ""
    echo -e "${YELLOW}💡 Tip: When ready for production, run:${NC}"
    echo -e "   ${GREEN}./scripts/python/autostart-python-apps.sh${NC}"
fi