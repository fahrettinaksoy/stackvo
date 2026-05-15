#!/bin/bash
###################################################################
# STACKVO PERMISSION MANAGEMENT MODULE
# Centralized permission handling for all generators
###################################################################

##
# Detect if running in container or on host
#
# Returns:
#   0 - Inside container
#   1 - On host
##
detect_container_environment() {
    if [ -f "/.dockerenv" ] || [ -f "/run/.containerenv" ]; then
        return 0  # Container
    else
        return 1  # Host
    fi
}

##
# Fix permissions for a directory
# Automatically detects container/host environment
#
# Parameters:
#   $1 - Target directory path
#   $2 - Optional: Container UID:GID (default: 100:101 nginx)
#
# Returns:
#   0 - Success
#   1 - Directory not found
##
fix_directory_permissions() {
    local target_dir=$1
    local container_uid_gid=${2:-"100:101"}
    
    if [ ! -d "$target_dir" ]; then
        log_warn "Directory not found: $target_dir"
        return 1
    fi
    
    if detect_container_environment; then
        # Container environment - use nginx user or custom
        if [ "$(id -u)" -eq 0 ]; then
            chown -R "$container_uid_gid" "$target_dir" 2>/dev/null || true
            log_info "Container: ownership set to $container_uid_gid for $target_dir"
        fi
    else
        # Host environment - use HOST_UID/HOST_GID
        if [ -n "${HOST_UID}" ] && [ -n "${HOST_GID}" ]; then
            sudo chown -R "${HOST_UID}:${HOST_GID}" "$target_dir" 2>/dev/null || true
            chmod -R 755 "$target_dir" 2>/dev/null || true
            log_info "Host: ownership set to ${HOST_UID}:${HOST_GID} for $target_dir"
        else
            log_warn "HOST_UID/HOST_GID not set, using chmod 777 for $target_dir"
            chmod -R 777 "$target_dir" 2>/dev/null || true
        fi
    fi
    
    return 0
}

##
# Fix permissions for a single file
#
# Parameters:
#   $1 - Target file path
#   $2 - Optional: Container UID:GID (default: 100:101 nginx)
#
# Returns:
#   0 - Success
#   1 - File not found
##
fix_file_permissions() {
    local target_file=$1
    local container_uid_gid=${2:-"100:101"}
    
    if [ ! -f "$target_file" ]; then
        log_warn "File not found: $target_file"
        return 1
    fi
    
    if detect_container_environment; then
        # Container environment
        if [ "$(id -u)" -eq 0 ]; then
            chown "$container_uid_gid" "$target_file" 2>/dev/null || true
            log_info "Container: file ownership set to $container_uid_gid"
        fi
    else
        # Host environment
        if [ -n "${HOST_UID}" ] && [ -n "${HOST_GID}" ]; then
            sudo chown "${HOST_UID}:${HOST_GID}" "$target_file" 2>/dev/null || true
            chmod 644 "$target_file" 2>/dev/null || true
            log_info "Host: file ownership set to ${HOST_UID}:${HOST_GID}"
        else
            chmod 666 "$target_file" 2>/dev/null || true
        fi
    fi
    
    return 0
}

##
# Fix permissions for generated directory
# Wrapper for backward compatibility with path-resolver.sh
#
# Returns:
#   0 - Success
##
fix_generated_permissions() {
    if [ ! -d "$GENERATED_DIR" ]; then
        return 0
    fi
    
    fix_directory_permissions "$GENERATED_DIR"
}
