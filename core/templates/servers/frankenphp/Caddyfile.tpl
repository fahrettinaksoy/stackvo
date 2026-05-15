{
    # FrankenPHP global options
    frankenphp

    # Disable automatic HTTPS in development (Traefik handles TLS)
    auto_https off
}

:80 {
    root * /var/www/html/{{DOCUMENT_ROOT}}

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
