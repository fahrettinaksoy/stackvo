#!/bin/bash
###################################################################
# STACKVO FRANKENPHP DOCKERFILE GENERATOR MODULE
# FrankenPHP (Caddy + embedded PHP) Dockerfile generation
# Note: FrankenPHP uses install-php-extensions instead of
#       docker-php-ext-install and pecl install
###################################################################

##
# Generate FrankenPHP extension install block
# FrankenPHP uses install-php-extensions (not docker-php-ext-install/pecl)
# Merges both standard and PECL extensions into a single command
#
# Parameters:
#   $1 - Extensions to install with docker-php-ext-install (space-separated)
#   $2 - Extensions to install with PECL (space-separated)
#
# Output:
#   Dockerfile RUN command using install-php-extensions
##
generate_frankenphp_extension_install() {
    local docker_ext_install=$1
    local pecl_install=$2

    # Merge all extensions into one list
    local all_extensions="$docker_ext_install $pecl_install"
    all_extensions=$(echo "$all_extensions" | xargs)  # Trim whitespace

    if [ -z "$all_extensions" ]; then
        return
    fi

    # Convert to array for last-element detection
    local ext_array=($all_extensions)
    local ext_count=${#ext_array[@]}
    local idx=0

    echo "# Install PHP extensions via install-php-extensions"
    echo "# FrankenPHP provides this tool (supports both standard and PECL extensions)"
    echo "RUN install-php-extensions \\"

    for ext in "${ext_array[@]}"; do
        ((idx++))
        if [ "$idx" -eq "$ext_count" ]; then
            echo "    $ext"
        else
            echo "    $ext \\"
        fi
    done

    echo ""
}

##
# Generate FrankenPHP Dockerfile
#
# Parameters:
#   $1 - Dockerfile path
#   $2 - PHP version
#   $3 - APT packages (space-separated)
#   $4 - Configure commands (ignored for FrankenPHP)
#   $5 - docker-php-ext-install extensions (space-separated)
#   $6 - PECL extensions (space-separated)
#   $7 - Project name
#   $8 - Project directory (for config files)
#   $9 - Document root
##
generate_frankenphp_dockerfile() {
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
    # NOTE: FrankenPHP uses dunglas/frankenphp image (NOT php:VERSION-fpm)
    echo "# syntax=docker/dockerfile:1.4" > "$dockerfile"
    echo "" >> "$dockerfile"
    cat >> "$dockerfile" <<EOF
# Auto-generated Dockerfile for $project_name
# Web Server: FrankenPHP (Caddy + embedded PHP)
# PHP Version: $php_version
FROM dunglas/frankenphp:1-php${php_version}-bookworm

EOF

    # System dependencies (reuse shared function)
    generate_system_dependencies_install "$apt_packages" >> "$dockerfile"

    # PHP extensions using install-php-extensions (FrankenPHP-specific)
    # Note: configure_commands are not needed with install-php-extensions
    generate_frankenphp_extension_install "$docker_ext_install" "$pecl_install" >> "$dockerfile"

    # Development tools (reuse shared function)
    generate_development_tools_install "$default_tools" "$composer_version" "$nodejs_version" "$default_apt_packages" >> "$dockerfile"

    # Generate FrankenPHP Caddyfile
    generate_frankenphp_caddyfile "$project_dir" "$document_root"

    # Copy Caddyfile
    cat >> "$dockerfile" <<'DOCKEREOF'

# Copy FrankenPHP Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

DOCKEREOF

    # Workdir and CMD
    cat >> "$dockerfile" <<'DOCKEREOF'

WORKDIR /var/www/html

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
DOCKEREOF
}

##
# Generate FrankenPHP Caddyfile
# Uses php_server directive (NOT php_fastcgi - no PHP-FPM process)
#
# Parameters:
#   $1 - Project directory
#   $2 - Document root
##
generate_frankenphp_caddyfile() {
    local project_dir=$1
    local document_root=$2

    cat > "$project_dir/Caddyfile" <<'CADDYCONF'
{
    # FrankenPHP global options
    frankenphp

    # Disable automatic HTTPS in development (Traefik handles TLS)
    auto_https off
}

:80 {
    root * /var/www/html/DOCUMENT_ROOT_PLACEHOLDER

    # FrankenPHP php_server directive (replaces php_fastcgi)
    # No separate PHP-FPM process needed
    php_server

    # Enable file server for static assets
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
