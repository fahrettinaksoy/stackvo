#!/bin/bash
###################################################################
# STACKVO SWOOLE COMPOSE GENERATOR MODULE
# Swoole HTTP server compose service generation
# Note: Uses port 8000 instead of 80 (Swoole default)
###################################################################

##
# Generate Swoole single container compose service
#
# Parameters:
#   $1 - Project name
#   $2 - Project path (container path)
#   $3 - Project domain
#   $4 - Document root
#   $5 - Host project path
#   $6 - Host logs path
#   $7 - Host generated configs dir
#   $8 - Host generated projects dir
##
generate_swoole_single_container() {
    local project_name=$1
    local project_path=$2
    local project_domain=$3
    local document_root=$4
    local host_project_path=$5
    local host_logs_path=$6
    local host_generated_configs_dir=$7
    local host_generated_projects_dir=$8

    # Sanitized project name for Traefik
    local traefik_safe_name=$(sanitize_project_name_for_traefik "$project_name")

    # Create compose service
    cat <<EOF
  ${project_name}:
    profiles: ["projects", "project-${project_name}"]  # --projects for all, --profile project-{name} for this project only
    build:
      context: ./projects/${project_name}
      dockerfile: Dockerfile
    image: stackvo-${project_name}:latest
    container_name: "stackvo-${project_name}"
    restart: unless-stopped

EOF

    # Volumes (no custom config mount for Swoole)
    generate_common_volumes "$host_project_path" "$host_logs_path" ""

    # Network
    cat <<EOF

    networks:
      - ${DOCKER_DEFAULT_NETWORK:-stackvo-net}

EOF

    # Traefik labels - IMPORTANT: port 8000 instead of 80
    generate_swoole_traefik_labels "$traefik_safe_name" "$project_domain"

    echo ""
}

##
# Generate Traefik labels for Swoole (port 8000)
# Swoole listens on port 8000, not 80 like traditional web servers
#
# Parameters:
#   $1 - Traefik-safe project name (sanitized)
#   $2 - Project domain
#
# Output:
#   Docker Compose labels block
##
generate_swoole_traefik_labels() {
    local traefik_safe_name=$1
    local project_domain=$2

    cat <<EOF
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${traefik_safe_name}.rule=Host(\`${project_domain}\`)"
      - "traefik.http.routers.${traefik_safe_name}.entrypoints=websecure"
      - "traefik.http.routers.${traefik_safe_name}.tls=true"
      - "traefik.http.services.${traefik_safe_name}.loadbalancer.server.port=8000"
EOF
}
