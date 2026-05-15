# Swoole Server

Swoole does not require traditional web server configuration files.

- **No web server config** — Swoole IS the HTTP server
- **No supervisord** — Swoole manages worker processes
- **No PHP-FPM** — Swoole handles PHP execution directly
- **Port 8000** — Default Swoole port (not 80)

## Base Image

Uses `php:VERSION-cli` (not fpm, not apache).

## CMD

```
php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000
```

## Required Extensions

- `swoole` — Automatically injected if missing
- `pcntl` — Automatically injected if missing
