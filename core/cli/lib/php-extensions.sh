#!/bin/bash
###################################################################
# PHP EXTENSION METADATA
# Defines required system dependencies for each extension
###################################################################

##
# Returns required system packages for extension
#
# Parameters:
#   $1 - Extension name
#
# Output:
#   Space-separated package list
##
get_extension_packages() {
    local ext=$1
    
    case "$ext" in
        # A
        apcu)
            echo ""  # PECL extension, no apt package required
            ;;
        
        # B
        bcmath)
            echo ""  # Built-in, no dependencies
            ;;
        bz2)
            echo "libbz2-dev"
            ;;
        
        # C
        calendar)
            echo ""  # Built-in, no dependencies
            ;;
        ctype)
            echo ""  # Built-in, no dependencies
            ;;
        curl)
            echo "libcurl4-openssl-dev"
            ;;
        
        # D
        dba)
            echo ""  # Built-in, no dependencies
            ;;
        dom)
            echo "libxml2-dev"
            ;;
        
        # E
        enchant)
            echo "libenchant-2-dev"
            ;;
        ev)
            echo ""  # PECL extension, no apt package required
            ;;
        event)
            echo "libevent-dev"
            ;;
        exif)
            echo ""  # Built-in, no dependencies
            ;;
        
        # F
        ffi)
            echo "libffi-dev"
            ;;
        fileinfo)
            echo ""  # Built-in, no dependencies
            ;;
        filter)
            echo ""  # Built-in, no dependencies
            ;;
        ftp)
            echo "libssl-dev"
            ;;
        
        # G
        gd)
            echo "libpng-dev libjpeg-dev libfreetype6-dev"
            ;;
        gettext)
            echo "gettext"
            ;;
        gmp)
            echo "libgmp-dev"
            ;;
        
        # H
        hash)
            echo ""  # Built-in, no dependencies
            ;;
        
        # I
        iconv)
            echo ""  # Built-in, no dependencies
            ;;
        igbinary)
            echo ""  # PECL extension, no apt package required
            ;;
        imagick)
            echo "libmagickwand-dev"
            ;;
        imap)
            echo "libc-client-dev libkrb5-dev"  # Required for PHP < 8.2
            ;;
        intl)
            echo "libicu-dev"
            ;;
        
        # J
        json)
            echo ""  # Built-in, no dependencies
            ;;
        
        # L
        ldap)
            echo "libldap2-dev"
            ;;
        lz4)
            echo "liblz4-dev"
            ;;
        
        # M
        mbstring)
            echo "libonig-dev"
            ;;
        mcrypt)
            echo "libmcrypt-dev"
            ;;
        memcache)
            echo "zlib1g-dev"
            ;;
        memcached)
            echo "libmemcached-dev zlib1g-dev"
            ;;
        mongodb)
            echo "libssl-dev libcurl4-openssl-dev"
            ;;
        mysqli)
            echo ""  # Built-in, no dependencies
            ;;
        mysqlnd)
            echo ""  # Built-in, no dependencies
            ;;
        
        # O
        odbc)
            echo "unixodbc-dev"
            ;;
        opcache)
            echo ""  # Built-in, no dependencies
            ;;
        openswoole)
            echo "libssl-dev libcurl4-openssl-dev"
            ;;
        openssl)
            echo "libssl-dev"
            ;;
        
        # P
        pcntl)
            echo ""  # Built-in, no dependencies
            ;;
        pdo)
            echo ""  # Built-in, no dependencies
            ;;
        pdo_dblib)
            echo "freetds-dev"
            ;;
        pdo_mysql)
            echo ""  # Built-in, no dependencies
            ;;
        pdo_odbc)
            echo "unixodbc-dev"
            ;;
        pdo_pgsql|pgsql)
            echo "libpq-dev"
            ;;
        pdo_sqlite)
            echo "libsqlite3-dev"
            ;;
        pdo_sqlsrv)
            echo "unixodbc-dev"
            ;;
        phalcon)
            echo ""  # PECL extension, no apt package required
            ;;
        phar)
            echo ""  # Built-in, no dependencies
            ;;
        posix)
            echo ""  # Built-in, no dependencies
            ;;
        pspell)
            echo "libpspell-dev"
            ;;
        
        # R
        readline)
            echo "libreadline-dev"
            ;;
        redis)
            echo ""  # PECL extension, no apt package required
            ;;
        
        # S
        session)
            echo ""  # Built-in, no dependencies
            ;;
        shmop)
            echo ""  # Built-in, no dependencies
            ;;
        simplexml)
            echo "libxml2-dev"
            ;;
        soap)
            echo "libxml2-dev"
            ;;
        sockets)
            echo ""  # Built-in, no dependencies
            ;;
        sodium)
            echo "libsodium-dev"
            ;;
        sqlite3)
            echo "libsqlite3-dev"
            ;;
        sqlsrv)
            echo "unixodbc-dev"
            ;;
        swoole)
            echo "libssl-dev libcurl4-openssl-dev"
            ;;
        sysvmsg)
            echo ""  # Built-in, no dependencies
            ;;
        sysvsem)
            echo ""  # Built-in, no dependencies
            ;;
        sysvshm)
            echo ""  # Built-in, no dependencies
            ;;
        
        # T
        tidy)
            echo "libtidy-dev"
            ;;
        tokenizer)
            echo ""  # Built-in, no dependencies
            ;;

        # U
        uv)
            echo "libuv1-dev"
            ;;

        # X
        xdebug)
            echo ""  # PECL extension, no apt package required
            ;;
        xml)
            echo "libxml2-dev"
            ;;
        xmlreader)
            echo "libxml2-dev"
            ;;
        xmlrpc)
            echo "libxml2-dev"
            ;;
        xmlwriter)
            echo "libxml2-dev"
            ;;
        xsl)
            echo "libxslt1-dev"
            ;;
        
        # Z
        zip)
            echo "libzip-dev"
            ;;
        zlib)
            echo "zlib1g-dev"
            ;;
        
        # S (continued - less common)
        snmp)
            echo "libsnmp-dev"
            ;;
        
        *)
            echo ""  # Extensions that don't require dependencies
            ;;
    esac
}

##
# Returns special configure command for extension
#
# Parameters:
#   $1 - Extension name
#
# Output:
#   Configure command (if any)
##
get_extension_configure() {
    local ext=$1
    
    case "$ext" in
        gd)
            echo "docker-php-ext-configure gd --with-freetype --with-jpeg"
            ;;
        imap)
            echo ""  # DEPRECATED: imap extension removed in PHP 8.2+
            ;;
        ldap)
            echo "docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu"
            ;;
        *)
            echo ""
            ;;
    esac
}

##
# Checks if extension should be installed via PECL
#
# Parameters:
#   $1 - Extension name
#
# Output:
#   0 = PECL, 1 = docker-php-ext-install
##
is_pecl_extension() {
    local ext=$1
    
    case "$ext" in
        apcu|ev|event|igbinary|imagick|lz4|mcrypt|memcache|memcached|mongodb|openswoole|pdo_sqlsrv|phalcon|redis|sqlsrv|swoole|uv|xdebug|xmlrpc)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

##
# Checks if extension is a Composer package (not a PHP extension)
#
# Parameters:
#   $1 - Extension name
#
# Output:
#   0 = Composer package, 1 = PHP extension
##
is_composer_package() {
    local ext=$1
    
    case "$ext" in
        monolog)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

##
# Checks if extension requires special setup (e.g., Oracle Instant Client)
#
# Parameters:
#   $1 - Extension name
#
# Output:
#   0 = Requires special setup, 1 = Standard installation
##
requires_special_setup() {
    local ext=$1
    
    case "$ext" in
        pdo_oci)
            return 0  # Requires Oracle Instant Client
            ;;
        *)
            return 1
            ;;
    esac
}

##
# Checks if extension is built-in (always available in PHP)
#
# Parameters:
#   $1 - Extension name
#   $2 - PHP version (optional, defaults to 8.0)
#
# Output:
#   0 = Built-in, 1 = Needs installation
##
is_builtin_extension() {
    local ext=$1
    local php_version=${2:-8.0}
    
    # Extensions that are ALWAYS built-in (all PHP versions)
    case "$ext" in
        core|date|pcre|reflection|spl|standard|random|zlib)
            return 0
            ;;
    esac
    
    # Extensions that are enabled by default in PHP 8.0+ (but still need to be available)
    # Only truly built-in extensions that cannot be disabled
    case "$ext" in
        tokenizer|json|filter|hash|session|ctype|iconv|fileinfo|phar|posix|openssl|dom|xml|simplexml|xmlreader|xmlwriter|libxml)
            return 0  # Built-in since PHP 8.0
            ;;
    esac
    
    return 1
}

##
# Checks if extension is deprecated/removed
#
# Parameters:
#   $1 - Extension name
#   $2 - PHP version (optional, defaults to 8.0)
#
# Output:
#   0 = Deprecated, 1 = Still available
##
is_deprecated_extension() {
    local ext=$1
    local php_version=${2:-8.0}
    
    # Extract major.minor version
    local major_minor=$(echo "$php_version" | cut -d. -f1-2)
    
    # Extensions removed in PHP 8.2+
    case "$ext" in
        imap)
            # Check if PHP version >= 8.2
            if [ "$(printf '%s\n' "8.2" "$major_minor" | sort -V | head -n1)" = "8.2" ]; then
                return 0  # Removed in PHP 8.2+
            fi
            ;;
    esac
    
    # Extensions removed in PHP 8.0+
    case "$ext" in
        xmlrpc)
            return 0  # Removed in PHP 8.0+
            ;;
    esac
    
    return 1
}

##
# Returns installation commands for development tool
#
# Parameters:
#   $1 - Tool name
#   $2 - Composer version (optional)
#   $3 - Node.js version (optional)
#
# Output:
#   Installation commands
##
get_tool_install_commands() {
    local tool=$1
    local composer_version=${2:-latest}
    local nodejs_version=${3:-20}
    
    case "$tool" in
        composer)
            echo "# Install Composer"
            echo "COPY --from=composer:${composer_version} /usr/bin/composer /usr/bin/composer"
            ;;
        nodejs)
            echo "# Install Node.js ${nodejs_version}.x"
            echo "RUN curl -fsSL https://deb.nodesource.com/setup_${nodejs_version}.x | bash - \\"
            echo "    && apt-get install -y nodejs \\"
            echo "    && rm -rf /var/lib/apt/lists/*"
            ;;
        git)
            echo "# Install Git"
            echo "RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*"
            ;;
        wget)
            echo "# Install Wget"
            echo "RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*"
            ;;
        unzip)
            echo "# Install Unzip"
            echo "RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*"
            ;;
        *)
            echo ""
            ;;
    esac
}

##
# Returns installation commands for APT packages
#
# Parameters:
#   $1 - Package list (comma-separated)
#
# Output:
#   Dockerfile RUN command
##
get_apt_packages_install_commands() {
    local packages=$1
    
    if [ -z "$packages" ]; then
        return 0
    fi
    
    # Convert comma-separated to space-separated
    local apt_packages=$(echo "$packages" | tr ',' ' ')
    
    echo "# Install System Packages"
    echo "RUN apt-get update && apt-get install -y \\"
    
    # Split packages and add each on new line
    for pkg in $apt_packages; do
        echo "    $pkg \\"
    done
    
    echo "    && rm -rf /var/lib/apt/lists/*"
}

##
# Returns recommended PECL extension version for PHP version
#
# Parameters:
#   $1 - Extension name
#   $2 - PHP version
#
# Output:
#   Version string or empty for latest
##
get_pecl_extension_version() {
    local ext=$1
    local php_version=$2
    local major_minor=$(echo "$php_version" | cut -d. -f1-2)
    
    case "$ext" in
        redis)
            # redis 6.x requires PHP 8.0+
            case "$major_minor" in
                8.0|8.1|8.2|8.3) echo "6.0.2" ;;
                8.4|8.5|9.0)     echo "6.3.0" ;;  # PHP 8.4+ - Latest stable
                *)               echo "" ;;        # Use latest for unknown versions
            esac
            ;;
        mongodb)
            # mongodb 1.20.x for PHP 8.3+, 1.19.x for PHP 8.0-8.2
            case "$major_minor" in
                8.0|8.1|8.2)     echo "1.19.4" ;;
                8.3)             echo "1.20.1" ;;
                8.4|8.5|9.0)     echo "1.20.1" ;;  # PHP 8.4+ - Latest stable
                *)               echo "" ;;
            esac
            ;;
        imagick)
            case "$major_minor" in
                8.0|8.1|8.2|8.3) echo "3.7.0" ;;
                8.4|8.5|9.0)     echo "3.8.1" ;;  # PHP 8.4+ - Latest stable (3.8.1)
                *)               echo "" ;;
            esac
            ;;
        xdebug)
            # xdebug 3.3.x for PHP 8.0-8.3, 3.4.x for PHP 8.4+
            case "$major_minor" in
                8.0|8.1|8.2|8.3) echo "3.3.2" ;;
                8.4|8.5|9.0)     echo "3.4.0" ;;  # PHP 8.4+ - Latest stable
                *)               echo "" ;;
            esac
            ;;
        swoole)
            # swoole 5.x for PHP 8.0-8.3, 6.x for PHP 8.4+
            case "$major_minor" in
                8.0|8.1|8.2|8.3) echo "5.1.5" ;;
                8.4|8.5|9.0)     echo "6.1.6" ;;  # PHP 8.4+ - Latest stable (6.1.6)
                *)               echo "" ;;
            esac
            ;;
        openswoole)
            # openswoole 22.x for PHP 8.0-8.3, 25.x for PHP 8.4+
            case "$major_minor" in
                8.0|8.1|8.2|8.3) echo "22.1.2" ;;
                8.4|8.5|9.0)     echo "25.2.0" ;;  # PHP 8.4+ - Latest stable (25.2.0)
                *)               echo "" ;;
            esac
            ;;
        ev)
            echo ""  # Use latest, stable across all versions
            ;;
        event)
            echo "3.1.4"  # Stable across all PHP 8.x versions
            ;;
        uv)
            echo "0.3.0"  # Stable across all PHP 8.x versions
            ;;
        memcached)
            case "$major_minor" in
                8.0|8.1|8.2|8.3) echo "3.3.0" ;;
                8.4|8.5|9.0)     echo "3.3.0" ;;  # PHP 8.4+ - Compatible
                *)               echo "" ;;
            esac
            ;;
        igbinary)
            case "$major_minor" in
                8.0|8.1|8.2|8.3) echo "3.2.16" ;;
                8.4|8.5|9.0)     echo "3.2.16" ;;  # PHP 8.4+ - Compatible
                *)               echo "" ;;
            esac
            ;;
        msgpack)
            echo "3.0.0"  # Stable across all versions
            ;;
        *)
            echo ""  # Use latest for unknown extensions
            ;;
    esac
}

##
# Returns PECL extension dependencies
#
# Parameters:
#   $1 - Extension name
#
# Output:
#   Space-separated list of dependency extensions
##
get_pecl_extension_dependencies() {
    local ext=$1
    
    case "$ext" in
        redis)
            echo "igbinary"  # Optional but recommended
            ;;
        *)
            echo ""
            ;;
    esac
}

##
# Checks if PECL extension is compatible with PHP version
#
# Parameters:
#   $1 - Extension name
#   $2 - PHP version
#
# Output:
#   0 = Compatible, 1 = Not compatible
##
is_pecl_extension_compatible() {
    local ext=$1
    local php_version=$2
    local major_minor=$(echo "$php_version" | cut -d. -f1-2)
    
    case "$ext" in
        swoole)
            # swoole requires PHP 8.0+
            if [ "$(printf '%s\n' "8.0" "$major_minor" | sort -V | head -n1)" = "8.0" ]; then
                return 0
            fi
            return 1
            ;;
        openswoole)
            # openswoole requires PHP 8.0+
            if [ "$(printf '%s\n' "8.0" "$major_minor" | sort -V | head -n1)" = "8.0" ]; then
                return 0
            fi
            return 1
            ;;
        uv)
            # uv requires PHP 7.0+
            if [ "$(printf '%s\n' "7.0" "$major_minor" | sort -V | head -n1)" = "7.0" ]; then
                return 0
            fi
            return 1
            ;;
        *)
            return 0  # Compatible by default
            ;;
    esac
}
