#!/usr/bin/env bash

###################################################################
# STACKVO INSTALLER
# Installs Stackvo CLI and sets up the environment
###################################################################

# Load common library and logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logger.sh"
source "$SCRIPT_DIR/../lib/env-loader.sh"
source "$SCRIPT_DIR/../lib/permissions.sh"

##
# Tüm CLI bash scriptlerine execute izni verir
##
fix_cli_permissions() {
    log_info "Fixing CLI script permissions..."
    
    # Find all .sh files in CLI directory and make them executable
    find "$CLI_DIR" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    log_success "CLI script permissions fixed"
}

# Check Docker Compose version
validate_docker_compose_version() {
    log_info "Checking Docker Compose version..."
    
    # Get current version
    local current_version=$(docker compose version 2>/dev/null | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/' | head -1)
    
    if [ -z "$current_version" ]; then
        log_error "Docker Compose not found! Please install Docker Compose first."
        log_info "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    log_info "Current Docker Compose version: v$current_version"
    
    # Extract major and minor version
    local current_major=$(echo "$current_version" | cut -d. -f1)
    local current_minor=$(echo "$current_version" | cut -d. -f2)
    
    # Minimum recommended version is 2.0.0 (Docker Compose v2 series)
    local min_major=2
    local min_minor=0
    
    if [ "$current_major" -lt "$min_major" ] || ([ "$current_major" -eq "$min_major" ] && [ "$current_minor" -lt "$min_minor" ]); then
        log_error "⚠️  Your Docker Compose version (v$current_version) is too old!"
        log_error "   Minimum required version: v${min_major}.${min_minor}.0"
        echo ""
        echo "   Please update Docker Compose manually:"
        echo "   - macOS: Update Docker Desktop from https://www.docker.com/products/docker-desktop"
        echo "   - Linux: Visit https://docs.docker.com/compose/install/"
        echo ""
        exit 1
    else
        log_success "Docker Compose version is sufficient (v$current_version >= v${min_major}.${min_minor}.0)"
    fi
}

print_banner "StackVo CLI Installer" "Local PHP Development Stack"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠  Running as root (sudo)${NC}"
    echo "   This may cause issues with Homebrew on macOS."
    echo "   Recommended: run without sudo — you'll be prompted when needed."
    echo ""
fi

print_section "Preparing environment"

fix_cli_permissions
validate_docker_compose_version

print_section "Registering system command"

if [ "$EUID" -eq 0 ]; then
    ln -sf "$CLI_DIR/stackvo.sh" /usr/local/bin/stackvo
    log_success "Symlink created at /usr/local/bin/stackvo"
else
    log_info "Creating system command (sudo required)..."
    if sudo ln -sf "$CLI_DIR/stackvo.sh" /usr/local/bin/stackvo; then
        log_success "Symlink created at /usr/local/bin/stackvo"
    else
        log_warn "Could not create symlink — the 'stackvo' shortcut will not be available"
    fi
fi

print_section "Generating SSL certificates"

if bash "$CLI_DIR/utils/generate-ssl-certs.sh" >/dev/null 2>&1; then
    log_success "SSL certificates generated"
    if [ -d "$STACKVO_ROOT/generated" ]; then
        fix_directory_permissions "$STACKVO_ROOT/generated"
    fi
else
    log_warn "SSL certificate generation failed — run later: ./core/cli/utils/generate-ssl-certs.sh"
fi

print_section "Configuring Docker network"

if ! docker info >/dev/null 2>&1; then
    log_error "Docker daemon is not running. Please start Docker Desktop and try again."
    exit 1
fi

if docker network inspect stackvo-net >/dev/null 2>&1; then
    log_success "Docker network 'stackvo-net' already exists"
elif docker network create stackvo-net >/dev/null 2>&1; then
    log_success "Docker network 'stackvo-net' created"
else
    log_error "Failed to create Docker network. Ensure Docker is running and try again."
    exit 1
fi

print_section "Creating project directories"

if [ ! -d "$STACKVO_ROOT/projects" ]; then
    mkdir -p "$STACKVO_ROOT/projects"
    fix_directory_permissions "$STACKVO_ROOT/projects"
    log_success "projects/ created"
else
    log_success "projects/ already exists"
fi

if [ ! -d "$STACKVO_ROOT/logs" ]; then
    mkdir -p "$STACKVO_ROOT/logs/services" "$STACKVO_ROOT/logs/projects"
    fix_directory_permissions "$STACKVO_ROOT/logs"
    log_success "logs/ created"
else
    log_success "logs/ already exists"
fi

print_done_box "Installation complete"
echo -e "${BLUE}── Available Commands ${NC}"
echo ""
printf "   %-32s %s\n" "./stackvo.sh generate"        "Generate all configuration files"
printf "   %-32s %s\n" "./stackvo.sh up"              "Start all Stackvo services"
printf "   %-32s %s\n" "./stackvo.sh down"            "Stop all Stackvo services"
printf "   %-32s %s\n" "./stackvo.sh restart"         "Restart all Stackvo services"
printf "   %-32s %s\n" "./stackvo.sh ps"              "List running containers"
printf "   %-32s %s\n" "./stackvo.sh logs [service]"  "View service logs"
printf "   %-32s %s\n" "./stackvo.sh pull"            "Pull latest Docker images"
printf "   %-32s %s\n" "./stackvo.sh --help"          "Show all available commands"
echo ""
echo -e "${BLUE}── Quick Start ${NC}"
echo ""
printf "   ${YELLOW}1.${NC} %-28s →  %s\n" "Generate configurations" "./stackvo.sh generate"
printf "   ${YELLOW}2.${NC} %-28s →  %s\n" "Start services"          "./stackvo.sh up"
printf "   ${YELLOW}3.${NC} %-28s →  %s\n" "StackVo dashboard"       "https://stackvo.loc"
printf "   ${YELLOW}4.${NC} %-28s →  %s\n" "Traefik dashboard"       "https://traefik.stackvo.loc"
echo ""
echo -e "${BLUE}── Resources ${NC}"
echo ""
printf "   %-12s %s\n" "Docs:"   "https://fahrettinaksoy.github.io/stackvo/"
printf "   %-12s %s\n" "GitHub:" "https://github.com/fahrettinaksoy/stackvo"
printf "   %-12s %s\n" "Help:"   "./stackvo.sh --help"
echo ""
