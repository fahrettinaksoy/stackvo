#!/bin/bash
set -eo pipefail

###################################################################
# STACKVO GENERATOR - PURE BASH IMPLEMENTATION
# Compatible with Bash 3.x+ (macOS default)
# No PHP dependency required!
#
# This file only serves as an orchestrator.
# All functions are separated into modules.
###################################################################

# Load common library
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Set ROOT_DIR for compatibility with existing code
readonly ROOT_DIR="$STACKVO_ROOT"

# Load libraries
source "$SCRIPT_DIR/../lib/logger.sh"
source "$SCRIPT_DIR/../lib/constants.sh"
source "$SCRIPT_DIR/../lib/env-loader.sh"
source "$SCRIPT_DIR/../lib/template-processor.sh"
source "$SCRIPT_DIR/../lib/generators/config.sh"
source "$SCRIPT_DIR/../lib/generators/compose.sh"
source "$SCRIPT_DIR/../lib/generators/traefik.sh"
source "$SCRIPT_DIR/../lib/generators/project.sh"
source "$SCRIPT_DIR/../lib/generators/stackvo-ui.sh"

##
# Show help message
##
show_help() {
    cat << EOF
Stackvo Generator - Dynamic Configuration Generator

Usage: ./stackvo generate [OPTIONS]

Options:
  -h, --help             Show this help message

Examples:
  # Generate all configurations
  ./stackvo generate

EOF
}

##
# Main orchestrator function
# Runs all generator modules in sequence
##
main() {
    local MODE=$1
    
    log_info "Stackvo Generator (Bash - No PHP!)"
    cd "$ROOT_DIR"
    
    # Load environment
    load_env
    
    # Generate SSL certificates (regenerate to include all project domains)
    if [ "$MODE" != "projects" ] && [ "$MODE" != "services" ]; then
        log_info "Generating SSL certificates..."
        if bash "$CLI_DIR/utils/generate-ssl-certs.sh"; then
            log_success "SSL certificates generated"
        else
            log_warn "SSL certificate generation failed. You can generate them later with: bash cli/utils/generate-ssl-certs.sh"
        fi
    fi
    
    case "$MODE" in
        projects)
            log_info "Generating projects only..."
            generate_projects
            log_success "Projects generation completed!"
            ;;
        services)
            log_info "Generating services only..."
            generate_stackvo_ui_configs
            generate_module_configs
            generate_base_compose
            generate_traefik_config
            generate_traefik_routes
            generate_dynamic_compose
            log_success "Services generation completed!"
            ;;
        *)
            # Generate everything
            generate_stackvo_ui_configs
            generate_module_configs
            generate_base_compose
            generate_traefik_config
            generate_traefik_routes
            generate_dynamic_compose
            generate_projects
            
            log_success "Generation completed!"
            ;;
    esac
}

##
# Parse command line arguments
##
MODE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        projects|services)
            MODE=$1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Normal generation
main "$MODE"
