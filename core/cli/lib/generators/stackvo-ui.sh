#!/bin/bash
###################################################################
# STACKVO UI GENERATOR MODULE
# Generates compose configuration for Stackvo UI (local build from core/ui)
###################################################################

##
# Generates Stackvo UI compose configuration
# Validates that core/ui sources exist before enabling local build.
#
# Returns:
#   0 - Success
#   1 - Error
##
generate_stackvo_ui_configs() {
    log_info "Checking Stackvo UI configuration..."

    if [ "${STACKVO_UI_ENABLE}" != "true" ]; then
        log_warn "Stackvo UI is disabled, skipping..."
        return 0
    fi

    if [ ! -f "$STACKVO_ROOT/core/ui/Dockerfile" ]; then
        log_error "core/ui/Dockerfile not found — cannot build Stackvo UI"
        return 1
    fi

    log_info "Stackvo UI will be built locally from core/ui/"
    log_success "Stackvo UI configuration ready"

    return 0
}

##
# Generates Stackvo UI compose snippet
# Called by compose generator to include in docker-compose.dynamic.yml
#
# Returns:
#   Compose YAML snippet
##
generate_stackvo_ui_compose() {
    local host_uid="${HOST_UID:-1000}"
    local host_gid="${HOST_GID:-1000}"
    local network="${DOCKER_DEFAULT_NETWORK:-stackvo-net}"

    cat <<EOF
  stackvo-ui:
    profiles: ["core"]
    build:
      context: ../core/ui
      dockerfile: Dockerfile
    image: stackvo-ui:local
    container_name: "stackvo-ui"
    restart: unless-stopped

    environment:
      NODE_ENV: production
      STACKVO_ROOT: /app
      PROJECTS_DIR: /app/projects
      GENERATED_DIR: /app/generated
      HOST_STACKVO_ROOT: \${PWD}
      HOST_UID: ${host_uid}
      HOST_GID: ${host_gid}

    volumes:
      - ../:/app:rw
      - ../.env:/app/.env:rw
      - ../core:/app/core:rw
      - ../projects:/app/projects:rw
      - ../generated:/app/generated:rw
      - ../logs:/app/logs:rw
      - /var/run/docker.sock:/var/run/docker.sock

    networks:
      - ${network}

    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.stackvo-ui.rule=Host(\`stackvo.loc\`)"
      - "traefik.http.routers.stackvo-ui.entrypoints=websecure"
      - "traefik.http.routers.stackvo-ui.tls=true"
      - "traefik.http.services.stackvo-ui.loadbalancer.server.port=80"

EOF
}
