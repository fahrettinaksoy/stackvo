#!/bin/bash
###################################################################
# STACKVO APACHE DOCKERFILE GENERATOR MODULE
# Apache + mod_php Dockerfile generation
###################################################################

##
# Generate Apache Dockerfile
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
generate_apache_dockerfile() {
    local dockerfile=$1
    local php_version=$2
    local apt_packages=$3
    local configure_commands=$4
    local docker_ext_install=$5
    local pecl_install=$6
    local project_name=$7
    local project_dir=$8
    local document_root=${9:-public}

    # Default tools
    local default_tools=${PHP_DEFAULT_TOOLS:-""}
    local default_apt_packages=${PHP_DEFAULT_APT_PACKAGES:-""}
    local composer_version=${PHP_TOOL_COMPOSER_VERSION:-latest}
    local nodejs_version=${PHP_TOOL_NODEJS_VERSION:-20}

    # Dockerfile header with BuildKit syntax
    echo "# syntax=docker/dockerfile:1.4" > "$dockerfile"
    echo "" >> "$dockerfile"
    generate_dockerfile_header "$project_name" "Apache + mod_php" "$php_version" "apache" >> "$dockerfile"

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

    # Apache modules
    generate_apache_modules >> "$dockerfile"

    # Configure Apache DocumentRoot
    cat >> "$dockerfile" <<EOF
# Configure Apache DocumentRoot to /var/www/html/${document_root}
ENV APACHE_DOCUMENT_ROOT /var/www/html/${document_root}
RUN sed -ri -e 's!/var/www/html!\${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf
RUN sed -ri -e 's!/var/www/!\${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EOF

    # Workdir
    echo "WORKDIR /var/www/html" >> "$dockerfile"
}

##
# Enable Apache modules
#
# Output:
#   Dockerfile RUN command
##
generate_apache_modules() {
    cat <<'EOF'

# Enable Apache modules
RUN a2enmod rewrite

EOF
}
