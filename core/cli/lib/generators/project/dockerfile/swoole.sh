#!/bin/bash
###################################################################
# STACKVO SWOOLE DOCKERFILE GENERATOR MODULE
# Swoole HTTP server Dockerfile generation
# Note: Uses php:VERSION-cli (not fpm) - Swoole IS the HTTP server
###################################################################

##
# Generate Swoole Dockerfile
#
# Parameters:
#   $1 - Dockerfile path
#   $2 - PHP version
#   $3 - APT packages (space-separated)
#   $4 - Configure commands
#   $5 - docker-php-ext-install extensions (space-separated)
#   $6 - PECL extensions (space-separated)
#   $7 - Project name
#   $8 - Project directory (for config files)
#   $9 - Document root
##
generate_swoole_dockerfile() {
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

    # Ensure swoole is in PECL install list (required for Swoole server)
    if ! echo " $pecl_install " | grep -q " swoole "; then
        pecl_install="$pecl_install swoole"
        # Add swoole system deps to apt_packages if not already present
        for dep in libssl-dev libcurl4-openssl-dev; do
            if ! echo " $apt_packages " | grep -q " $dep "; then
                apt_packages="$apt_packages $dep"
            fi
        done
    fi

    # Ensure pcntl is in docker-php-ext-install list (required for Swoole)
    if ! echo " $docker_ext_install " | grep -q " pcntl "; then
        docker_ext_install="$docker_ext_install pcntl"
    fi

    # Deduplicate apt packages
    apt_packages=$(echo "$apt_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ')

    # Dockerfile header with BuildKit syntax
    # NOTE: Swoole uses php:VERSION-cli (NOT fpm, NOT apache)
    echo "# syntax=docker/dockerfile:1.4" > "$dockerfile"
    echo "" >> "$dockerfile"
    cat >> "$dockerfile" <<EOF
# Auto-generated Dockerfile for $project_name
# Server: Swoole
# PHP Version: $php_version
# Note: Uses php-cli image - Swoole IS the HTTP server
FROM php:${php_version}-cli

EOF

    # System dependencies (reuse shared function)
    generate_system_dependencies_install "$apt_packages" >> "$dockerfile"

    # Configure commands
    if [ -n "$configure_commands" ]; then
        echo -e "$configure_commands" >> "$dockerfile"
        echo "" >> "$dockerfile"
    fi

    # PHP extensions (reuse shared function - docker-php-ext-install works in cli image)
    generate_php_extension_install "$docker_ext_install" "$pecl_install" "$php_version" >> "$dockerfile"

    # Development tools (reuse shared function)
    generate_development_tools_install "$default_tools" "$composer_version" "$nodejs_version" "$default_apt_packages" >> "$dockerfile"

    # Expose Swoole port
    cat >> "$dockerfile" <<'DOCKEREOF'

# Expose Swoole port
EXPOSE 8000

DOCKEREOF

    # Create Swoole fallback server for non-Laravel projects
    cat >> "$dockerfile" <<DOCKEREOF
# Swoole fallback server for non-Laravel projects
RUN { \\
    echo '<?php'; \\
    echo '\$http = new Swoole\\\\HTTP\\\\Server("0.0.0.0", 8000);'; \\
    echo '\$http->set(["document_root" => "/var/www/html/${document_root}", "enable_static_handler" => true]);'; \\
    echo '\$http->on("request", function (\$request, \$response) {'; \\
    echo '    ob_start();'; \\
    echo '    include "/var/www/html/${document_root}/index.php";'; \\
    echo '    \$response->end(ob_get_clean());'; \\
    echo '});'; \\
    echo '\$http->start();'; \\
    } > /swoole-server.php

DOCKEREOF

    # Create entrypoint script
    cat >> "$dockerfile" <<'DOCKEREOF'
# Entrypoint: Laravel Octane if available, otherwise standalone Swoole HTTP server
RUN { \
    echo '#!/bin/bash'; \
    echo 'cd /var/www/html'; \
    echo 'if [ -f artisan ]; then'; \
    echo '    exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000'; \
    echo 'else'; \
    echo '    exec php /swoole-server.php'; \
    echo 'fi'; \
    } > /swoole-entrypoint.sh && chmod +x /swoole-entrypoint.sh

WORKDIR /var/www/html

CMD ["/swoole-entrypoint.sh"]
DOCKEREOF
}
