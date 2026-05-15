#!/bin/bash
###################################################################
# STACKVO PROJECT PATH RESOLVER MODULE
# Host/container path resolution and permission management
###################################################################

# Load permission management module
source "$(dirname "${BASH_SOURCE[0]}")/../../permissions.sh"

##
# Resolve host paths
# Detects whether we are running in container or on host
# Returns correct paths based on execution environment
#
# Output:
#   HOST_ROOT_DIR=<path> format
##
resolve_host_paths() {
    local HOST_ROOT_DIR="$ROOT_DIR"
    
    if detect_container_environment; then
        # We are in container - use host path
        if [ -n "$HOST_STACKVO_ROOT" ]; then
            HOST_ROOT_DIR="$HOST_STACKVO_ROOT"
            log_info "Running in container, using host path: $HOST_ROOT_DIR"
        else
            log_warn "Running in container but HOST_STACKVO_ROOT is not set, volume mounts may fail"
        fi
    fi
    
    echo "HOST_ROOT_DIR=$HOST_ROOT_DIR"
}

##
# Fix permissions for generated directory
# Wrapper for backward compatibility - uses centralized permissions.sh
#
# Returns:
#   0 - Success
##
fix_generated_permissions() {
    if [ ! -d "$GENERATED_DIR" ]; then
        return 0
    fi
    
    # Use centralized permission function
    fix_directory_permissions "$GENERATED_DIR"
}

##
# Calculate host paths for project
#
# Parameters:
#   $1 - Project name
#   $2 - Host root directory
#
# Output:
#   HOST_PROJECT_PATH=<path>
#   HOST_LOGS_PATH=<path>
#   HOST_GENERATED_CONFIGS_DIR=<path>
#   HOST_GENERATED_PROJECTS_DIR=<path>
##
calculate_project_host_paths() {
    local project_name=$1
    local host_root_dir=$2
    
    echo "HOST_PROJECT_PATH=${host_root_dir}/projects/${project_name}"
    echo "HOST_LOGS_PATH=${host_root_dir}/logs/projects/${project_name}"
    echo "HOST_GENERATED_CONFIGS_DIR=${host_root_dir}/generated/configs"
    echo "HOST_GENERATED_PROJECTS_DIR=${host_root_dir}/generated/projects"
}

##
# Find custom config file mount path
# Priority order: .stackvo/config > project_root/config > generated/config
#
# Parameters:
#   $1 - Project path (container path)
#   $2 - Host project path
#   $3 - Config filename (e.g., nginx.conf, apache.conf, Caddyfile)
#   $4 - Generated config path (fallback)
#
# Output:
#   Config mount line (empty string = no mount, use generated)
##
get_config_mount_path() {
    local project_path=$1
    local host_project_path=$2
    local config_filename=$3
    local generated_config=$4
    
    # Is there a custom config in .stackvo/ directory?
    if [ -f "$project_path/.stackvo/$config_filename" ]; then
        echo "      - ${host_project_path}/.stackvo/${config_filename}:${generated_config}:ro"
        return 0
    fi
    
    # Is there a custom config in project root?
    if [ -f "$project_path/$config_filename" ]; then
        echo "      - ${host_project_path}/${config_filename}:${generated_config}:ro"
        return 0
    fi
    
    # No custom config - return empty string (generated config from Dockerfile will be used)
    echo ""
}
