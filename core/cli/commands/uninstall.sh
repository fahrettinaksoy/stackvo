#!/usr/bin/env bash

###################################################################
# STACKVO UNINSTALLER
# Removes all Docker resources and files related to Stackvo project
###################################################################

# Load common library and logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"

# Silently fix CLI script permissions
find "$CLI_DIR" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

print_banner "StackVo Uninstaller" "This will remove containers, images, volumes and data"

echo -e "${YELLOW}The following will be removed:${NC}"
echo ""
echo "   • All Stackvo Docker containers   (stackvo-* prefix)"
echo "   • All Docker images used by those containers"
echo "   • All Stackvo Docker volumes      (stackvo-* prefix)"
echo "   • Stackvo Docker network          (stackvo-net)"
echo "   • System command                  (/usr/local/bin/stackvo)"
echo "   • generated/  logs/  cache/  projects/"
echo ""
echo -e "${RED}⚠  Database data and project files will be DELETED permanently.${NC}"
echo ""

read -p "Type 'yes' to continue: " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${BLUE}Cancelled.${NC}"
    exit 0
fi

cd "$STACKVO_ROOT"

#─── Step 1: Containers ────────────────────────────────────────────────
print_section "[1/8] Stopping containers"

STACKVO_IMAGES=$(docker ps -a --filter "name=stackvo-" --format "{{.Image}}" | sort -u)
container_count=$(docker ps -a --filter "name=stackvo-" --format "{{.Names}}" | wc -l | tr -d ' ')

if [ -f "generated/stackvo.yml" ]; then
    docker compose \
        -f generated/stackvo.yml \
        -f generated/docker-compose.dynamic.yml \
        -f generated/docker-compose.projects.yml \
        down -v --remove-orphans >/dev/null 2>&1 || true
fi

docker ps -a --format "{{.Names}}" | grep "^stackvo-" | xargs -r docker rm -f >/dev/null 2>&1 || true
log_success "${container_count} container(s) removed"

#─── Step 2: Images ────────────────────────────────────────────────────
print_section "[2/8] Removing Docker images"

image_count=0
if [ -n "$STACKVO_IMAGES" ]; then
    for img in $STACKVO_IMAGES; do
        if docker rmi -f "$img" >/dev/null 2>&1; then
            ((image_count++))
        fi
    done
fi
log_success "${image_count} image(s) removed"

dangling_count=$(docker images -f "dangling=true" -q | wc -l | tr -d ' ')
docker images -f "dangling=true" -q | xargs -r docker rmi -f >/dev/null 2>&1 || true
[ "$dangling_count" -gt 0 ] && log_success "${dangling_count} dangling image(s) removed"

docker builder prune -af --filter "label=project=stackvo" >/dev/null 2>&1 || true
docker builder prune -af --filter "label!=project=stackvo" >/dev/null 2>&1 || true
log_success "Build cache cleared"

#─── Step 3: Volumes ───────────────────────────────────────────────────
print_section "[3/8] Removing Docker volumes"

volume_count=$(docker volume ls --format "{{.Name}}" | grep -c "stackvo" || true)
docker volume ls --format "{{.Name}}" | grep "stackvo" | xargs -r docker volume rm >/dev/null 2>&1 || true
log_success "${volume_count} volume(s) removed"

#─── Step 4: Network ───────────────────────────────────────────────────
print_section "[4/8] Removing Docker network"

if docker network rm stackvo-net >/dev/null 2>&1; then
    log_success "Network 'stackvo-net' removed"
else
    log_warn "Network 'stackvo-net' not found or already removed"
fi

#─── Step 5: System command ────────────────────────────────────────────
print_section "[5/8] Removing system command"

if [ -L /usr/local/bin/stackvo ] || [ -f /usr/local/bin/stackvo ]; then
    sudo rm -f /usr/local/bin/stackvo 2>/dev/null || true
    log_success "Symlink /usr/local/bin/stackvo removed"
else
    log_warn "Symlink not found, skipping"
fi

#─── Step 6: Generated files ───────────────────────────────────────────
print_section "[6/8] Cleaning generated directory"

sudo rm -rf "$STACKVO_ROOT/generated/" 2>/dev/null || true
sudo rm -f "$STACKVO_ROOT/stackvo.yml" 2>/dev/null || true
sudo rm -f "$STACKVO_ROOT/docker-compose.dynamic.yml" 2>/dev/null || true
sudo rm -f "$STACKVO_ROOT/docker-compose.projects.yml" 2>/dev/null || true
sudo rm -rf "$STACKVO_ROOT/core/traefik/" 2>/dev/null || true
sudo rm -rf "$STACKVO_ROOT/core/generated-configs/" 2>/dev/null || true
sudo rm -rf "$STACKVO_ROOT/core/generated/" 2>/dev/null || true
sudo rm -rf "$STACKVO_ROOT/core/certs/" 2>/dev/null || true
log_success "generated/ and legacy locations cleaned"

#─── Step 7: Logs ──────────────────────────────────────────────────────
print_section "[7/8] Cleaning log files"

sudo rm -rf "$STACKVO_ROOT/logs/" 2>/dev/null || true
log_success "logs/ removed"

#─── Step 8: Projects ──────────────────────────────────────────────────
print_section "[8/8] Cleaning project files"

sudo rm -rf "$STACKVO_ROOT/projects/" 2>/dev/null || true
[ -d "$STACKVO_ROOT/cache/" ] && sudo rm -rf "$STACKVO_ROOT/cache/" 2>/dev/null || true

if [ -d "$STACKVO_ROOT/core/templates/ui/tools/" ]; then
    rm -f "$STACKVO_ROOT/core/templates/ui/tools/Dockerfile" 2>/dev/null || true
    rm -f "$STACKVO_ROOT/core/templates/ui/tools/nginx.conf" 2>/dev/null || true
    rm -f "$STACKVO_ROOT/core/templates/ui/tools/supervisord.conf" 2>/dev/null || true
    rm -f "$STACKVO_ROOT/core/templates/ui/tools/Dockerfile.backup" 2>/dev/null || true
    rm -f "$STACKVO_ROOT/core/templates/ui/tools/nginx.conf.backup" 2>/dev/null || true
    rm -f "$STACKVO_ROOT/core/templates/ui/tools/supervisord.conf.backup" 2>/dev/null || true
fi
log_success "projects/, cache/ and generated UI tool files removed"

#─── Done ──────────────────────────────────────────────────────────────
print_done_box "StackVo successfully uninstalled"

echo -e "${BLUE}── Removed ${NC}"
echo ""
printf "   ${GREEN}✓${NC}  %s\n" "$container_count container(s)"
printf "   ${GREEN}✓${NC}  %s\n" "$image_count image(s) + $dangling_count dangling"
printf "   ${GREEN}✓${NC}  %s\n" "$volume_count volume(s)"
printf "   ${GREEN}✓${NC}  %s\n" "Network, symlink, generated/, logs/, projects/, cache/"
echo ""
echo -e "${BLUE}── Preserved ${NC}"
echo ""
echo "   • .env configuration"
echo "   • core/templates/  (template files)"
echo "   • core/cli/        (CLI commands)"
echo ""
echo -e "${BLUE}── To Reinstall ${NC}"
echo ""
printf "   ${YELLOW}1.${NC} %s\n" "./stackvo.sh install"
printf "   ${YELLOW}2.${NC} %s\n" "./stackvo.sh generate"
printf "   ${YELLOW}3.${NC} %s\n" "./stackvo.sh up"
echo ""
