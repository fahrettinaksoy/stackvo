#!/bin/bash
###################################################################
# STACKVO CADDY DOCKERFILE GENERATOR MODULE
# Caddy + PHP-FPM + Supervisord Dockerfile generation
###################################################################

##
# Generate Caddy Dockerfile
#
# Parameters:
#   $1 - Dockerfile path
#   $2 - PHP version
#   $3 - APT packages (space-separated)
#   $4 - Configure commands
#   $5 - docker-php-ext-install extensions
#   $6 - PECL extensions
#   $7 - Project name
#   $8 - Project directory (for config files)
#   $9 - Document root
##
generate_caddy_dockerfile() {
    local dockerfile=$1
    local php_version=$2
    local apt_packages=$3
    local configure_commands=$4
    local docker_ext_install=$5
    local pecl_install=$6
    local project_name=$7
    local project_dir=$8
    local document_root=$9
    
    # Default tools
    local default_tools=${PHP_DEFAULT_TOOLS:-""}
    local default_apt_packages=${PHP_DEFAULT_APT_PACKAGES:-""}
    local composer_version=${PHP_TOOL_COMPOSER_VERSION:-latest}
    local nodejs_version=${PHP_TOOL_NODEJS_VERSION:-20}
    
    # Dockerfile header with BuildKit syntax
    echo "# syntax=docker/dockerfile:1.4" > "$dockerfile"
    echo "" >> "$dockerfile"
    generate_dockerfile_header "$project_name" "Caddy + PHP-FPM" "$php_version" "fpm" >> "$dockerfile"
    
    # Install Caddy and Supervisord with BuildKit cache
    cat >> "$dockerfile" <<'EOF'
# Install Caddy and Supervisord with BuildKit cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    debian-keyring \
    debian-archive-keyring \
    apt-transport-https \
    curl \
    supervisor \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update \
    && apt-get install -y caddy \
    && rm -rf /var/lib/apt/lists/*

EOF
    
    # System dependencies
    generate_system_dependencies_install "$apt_packages" >> "$dockerfile"
    
    # Configure commands
    if [ -n "$configure_commands" ]; then
        echo -e "$configure_commands" >> "$dockerfile"
        echo "" >> "$dockerfile"
    fi
    
    # PHP extensions
    generate_php_extension_install "$docker_ext_install" "$pecl_install" "$php_version" >> "$dockerfile"
    
    # Development tools
    generate_development_tools_install "$default_tools" "$composer_version" "$nodejs_version" "$default_apt_packages" >> "$dockerfile"
    
    # Generate Caddyfile
    generate_caddyfile "$project_dir" "$document_root"
    
    # Generate Supervisord config
    generate_supervisord_config "$project_dir" "caddy" "/usr/bin/caddy run --config /etc/caddy/Caddyfile"
    
    # Caddy and PHP-FPM configuration
    cat >> "$dockerfile" <<'DOCKEREOF'

DOCKEREOF
    
    # PHP-FPM TCP config
    generate_php_fpm_tcp_config >> "$dockerfile"
    
    cat >> "$dockerfile" <<'DOCKEREOF'

# Copy Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Copy Supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

DOCKEREOF
    
    # Entrypoint script
    generate_entrypoint_script "caddy" >> "$dockerfile"
    
    # Workdir and CMD
    cat >> "$dockerfile" <<'DOCKEREOF'

WORKDIR /var/www/html

# Use entrypoint to create log directories before starting supervisord
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
DOCKEREOF
}

##
# Generate Caddyfile
#
# Parameters:
#   $1 - Project directory
#   $2 - Document root
##
generate_caddyfile() {
    local project_dir=$1
    local document_root=$2
    
    cat > "$project_dir/Caddyfile" <<'CADDYCONF'
:80 {
    root * /var/www/html/DOCUMENT_ROOT_PLACEHOLDER
    
    # Enable PHP-FPM (localhost - same container)
    php_fastcgi 127.0.0.1:9000
    
    # Enable file server
    file_server
    
    # Logging
    log {
        output stdout
        format console
    }
}
CADDYCONF

    # Replace placeholder with actual document root (cross-platform compatible)
    sed "s|DOCUMENT_ROOT_PLACEHOLDER|$document_root|g" "$project_dir/Caddyfile" > "$project_dir/Caddyfile.tmp" && mv "$project_dir/Caddyfile.tmp" "$project_dir/Caddyfile"
}
