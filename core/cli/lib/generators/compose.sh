#!/bin/bash
###################################################################
# STACKVO COMPOSE GENERATOR MODULE
# Docker Compose file generation
###################################################################

# Load permission management module
source "$(dirname "${BASH_SOURCE[0]}")/../permissions.sh"


##
# Generates base stackvo.yml file (Traefik and network)
#
# Returns:
#   0 - Success
##
generate_base_compose() {
    log_info "Generating stackvo.yml (base compose)..."
    
    # Create generated directory
    mkdir -p "$GENERATED_DIR"
    
    # Create logs directory and set ownership
    mkdir -p "$ROOT_DIR/logs/projects" "$ROOT_DIR/logs/services"
    
    # Fix permissions for logs directory
    fix_directory_permissions "$ROOT_DIR/logs"
    
    local output="$GENERATED_DIR/stackvo.yml"
    local template="$ROOT_DIR/core/compose/base.yml"
    
    if [ -f "$template" ]; then
        if ! render_template "$template" > "$output" 2>/dev/null; then
            log_error "Failed to generate stackvo.yml from template"
            return 1
        fi
    else
        # Fallback: create minimal base compose
        if ! cat > "$output" <<'EOF'
services:
  traefik:
    image: traefik:latest
    container_name: stackvo-traefik
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedByDefault=false"
      - "--providers.file.directory=/etc/traefik/dynamic"
      - "--providers.file.watch=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./core/traefik/traefik.yml:/etc/traefik/traefik.yml:ro"
      - "./core/traefik/dynamic:/etc/traefik/dynamic:ro"
      - "./core/certs:/certs:ro"
    networks:
      - stackvo-net

networks:
  stackvo-net:
    name: stackvo-net
    driver: bridge
EOF
        then
            log_error "Failed to create stackvo.yml"
            return 1
        fi
    fi
    
    log_success "Generated stackvo.yml"
}

##
# Create log directory for a service
#
# This ensures Docker can mount the log volumes without permission errors
# Works on macOS, Linux, and Windows (WSL)
#
# Parameters:
#   $1 - Service name (e.g., "blackfire", "mysql", "cassandra")
##
create_service_log_directory() {
    local service_name=$1
    local log_dir="${ROOT_DIR}/logs/services/${service_name}"
    
    # Create directory if it doesn't exist
    if [[ ! -d "${log_dir}" ]]; then
        mkdir -p "${log_dir}"
        
        # Fix permissions using centralized function
        fix_directory_permissions "${log_dir}"
    fi
}

##
# Generates dynamic docker-compose.dynamic.yml file (services)
#
# Returns:
#   0 - Success
##
generate_dynamic_compose() {
    log_info "Generating docker-compose.dynamic.yml..."
    
    # Create generated directory
    mkdir -p "$GENERATED_DIR"
    
    local output="$GENERATED_DIR/docker-compose.dynamic.yml"
    
    if ! echo "services:" > "$output" 2>/dev/null; then
        log_error "Failed to create docker-compose.dynamic.yml"
        return 1
    fi
    
    echo "" >> "$output"
    
    # Service definitions: "ENABLE_VAR:template/path"
    local services=(
        # Databases
        "SERVICE_MYSQL_ENABLE:services/mysql/docker-compose.mysql.tpl"
        "SERVICE_MARIADB_ENABLE:services/mariadb/docker-compose.mariadb.tpl"
        "SERVICE_POSTGRES_ENABLE:services/postgres/docker-compose.postgres.tpl"
        "SERVICE_MONGO_ENABLE:services/mongo/docker-compose.mongo.tpl"
        "SERVICE_CASSANDRA_ENABLE:services/cassandra/docker-compose.cassandra.tpl"
        
        # Caching
        "SERVICE_REDIS_ENABLE:services/redis/docker-compose.redis.tpl"
        "SERVICE_MEMCACHED_ENABLE:services/memcached/docker-compose.memcached.tpl"
        
        # Message Queues
        "SERVICE_RABBITMQ_ENABLE:services/rabbitmq/docker-compose.rabbitmq.tpl"
        "SERVICE_KAFKA_ENABLE:services/kafka/docker-compose.kafka.tpl"
        
        # Search
        "SERVICE_ELASTICSEARCH_ENABLE:services/elasticsearch/docker-compose.elasticsearch.tpl"
        
        # Monitoring
        "SERVICE_KIBANA_ENABLE:services/kibana/docker-compose.kibana.tpl"
        "SERVICE_GRAFANA_ENABLE:services/grafana/docker-compose.grafana.tpl"
        
        # Tools
        "SERVICE_MAILHOG_ENABLE:services/mailhog/docker-compose.mailhog.tpl"
        "SERVICE_PHPMYADMIN_ENABLE:services/phpmyadmin/docker-compose.phpmyadmin.tpl"
        "SERVICE_ADMINER_ENABLE:services/adminer/docker-compose.adminer.tpl"
        "SERVICE_PGADMIN_ENABLE:services/pgadmin/docker-compose.pgadmin.tpl"
        "SERVICE_KAFBAT_ENABLE:services/kafbat/docker-compose.kafbat.tpl"
        "SERVICE_MONGO_EXPRESS_ENABLE:services/mongo-express/docker-compose.mongo-express.tpl"
        "SERVICE_PHPCACHEADMIN_ENABLE:services/phpcacheadmin/docker-compose.phpcacheadmin.tpl"
        "SERVICE_BLACKFIRE_ENABLE:services/blackfire/docker-compose.blackfire.tpl"
    )
    
    # Process all services
    for service_def in "${services[@]}"; do
        local enable_flag="${service_def%%:*}"
        local template_path="${service_def##*:}"
        
        # Include service template
        include_module "$enable_flag" "$template_path" >> "$output"
        
        # Create log directory for services that have log volumes
        # Extract service name from template path (e.g., "services/mysql/..." -> "mysql")
        if [[ "$template_path" == services/* ]]; then
            local service_name
            service_name=$(echo "$template_path" | cut -d'/' -f2)
            
            # Check if service is enabled
            eval "local enabled=\${${enable_flag}:-false}"
            if [ "$enabled" = "true" ]; then
                # Create log directory for this service
                create_service_log_directory "$service_name"
                
                # Special case: Kafka also needs zookeeper log directory
                if [ "$service_name" = "kafka" ]; then
                    create_service_log_directory "zookeeper"
                fi
            fi
        fi
    done
    
    # Stackvo Web UI - built locally from core/ui
    if [ "${STACKVO_UI_ENABLE}" = "true" ]; then
        log_info "Including Stackvo UI (local build from core/ui)..."
        source "$ROOT_DIR/core/cli/lib/generators/stackvo-ui.sh"
        generate_stackvo_ui_compose >> "$output"
    fi
    
    # Add volumes section
    echo "" >> "$output"
    echo "volumes:" >> "$output"
    
    # Extract volume names to temp file (use /tmp for read-only root)
    local volumes_tmp="/tmp/.stackvo-volumes.tmp"
    > "$volumes_tmp"  # Clear temp file
    
    # Use find instead of glob for Bash 3.x compatibility
    find "$ROOT_DIR/core/templates" -name "*.tpl" -type f | while read -r tpl; do
        # Extract volume names
        awk '/^volumes:/,0 {
            if (/^  [a-z]/) {
                gsub(/:.*/, "")
                gsub(/^  /, "")
                if (length($0) > 0) print "  " $0 ": {}"
            }
        }' "$tpl" >> "$volumes_tmp" 2>/dev/null || true
    done
    
    # Sort and append unique volumes
    sort -u "$volumes_tmp" >> "$output"
    rm -f "$volumes_tmp"
    
    log_success "Generated docker-compose.dynamic.yml"
}
