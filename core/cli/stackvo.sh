#!/usr/bin/env bash

# Load common library for shared paths and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

COMMAND=$1
shift

case "$COMMAND" in
    generate)
        SUBCOMMAND=$1
        shift
        case "$SUBCOMMAND" in
            projects)
                bash "$CLI_DIR/commands/generate.sh" projects
                ;;
            services)
                bash "$CLI_DIR/commands/generate.sh" services
                ;;
            "")
                # No subcommand, generate everything
                bash "$CLI_DIR/commands/generate.sh" "$@"
                ;;
            *)
                echo "Unknown generate subcommand: $SUBCOMMAND"
                echo ""
                echo "Usage:"
                echo "  stackvo generate              → generate everything"
                echo "  stackvo generate projects     → generate only projects"
                echo "  stackvo generate services     → generate only services"
                exit 1
                ;;
        esac
        ;;

    up)
        # Parse flags for selective startup
        START_MODE="minimal"  # Default: minimal (core only)
        CUSTOM_PROFILES=()
        
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --all)
                    START_MODE="all"
                    shift
                    ;;
                --services)
                    START_MODE="services"
                    shift
                    ;;
                --projects)
                    START_MODE="projects"
                    shift
                    ;;
                --profile)
                    CUSTOM_PROFILES+=("$2")
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        
        # Build profile arguments
        PROFILE_ARGS=""
        case "$START_MODE" in
            minimal)
                PROFILE_ARGS="--profile core --profile tools"
                ;; 
            services)
                PROFILE_ARGS="--profile core --profile services --profile tools"
                ;;
            projects)
                PROFILE_ARGS="--profile core --profile projects --profile tools"
                ;;
            all)
                PROFILE_ARGS="--profile core --profile services --profile projects --profile tools"
                ;;
        esac
        
        # Auto-enable services based on .env (only in minimal mode)
        if [ "$START_MODE" = "minimal" ]; then
            # Load .env file
            if [ -f "$STACKVO_ROOT/.env" ]; then
                # Read enabled services from .env
                while IFS='=' read -r key value; do
                    # Skip comments and empty lines
                    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
                    
                    # Check for SERVICE_*_ENABLE=true
                    if [[ "$key" =~ ^SERVICE_([A-Z_]+)_ENABLE$ ]] && [ "$value" = "true" ]; then
                        SERVICE_NAME="${BASH_REMATCH[1]}"
                        SERVICE_PROFILE=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]')
                        PROFILE_ARGS="$PROFILE_ARGS --profile $SERVICE_PROFILE"
                    fi
                done < "$STACKVO_ROOT/.env"
            fi
        fi
        
        # Add custom profiles if specified
        for profile in "${CUSTOM_PROFILES[@]}"; do
            PROFILE_ARGS="$PROFILE_ARGS --profile $profile"
            echo "  + Including profile: $profile"
        done
        
        # Use Docker Compose's native progress output
        echo ""
        echo "🚀 Stackvo Başlatılıyor (minimal mod)"
        echo ""
        
        # Pull, build and start operations sequentially
        docker compose --env-file "$STACKVO_ROOT/.env" "${COMPOSE_FILES[@]}" $PROFILE_ARGS pull
        docker compose --env-file "$STACKVO_ROOT/.env" "${COMPOSE_FILES[@]}" $PROFILE_ARGS build
        docker compose --env-file "$STACKVO_ROOT/.env" "${COMPOSE_FILES[@]}" $PROFILE_ARGS up -d --remove-orphans
        
        echo ""
        echo "✅ Stackvo started successfully!"
        ;;

    down)
        echo ""
        echo "🛑 Stopping Stackvo..."
        echo ""
        docker compose --env-file "$STACKVO_ROOT/.env" "${COMPOSE_FILES[@]}" --profile services --profile projects down
        echo ""
        echo "✅ All services and projects stopped successfully!"
        ;;

    restart)
        echo ""
        echo "🔄 Restarting Stackvo..."
        echo ""
        docker compose --env-file "$STACKVO_ROOT/.env" "${COMPOSE_FILES[@]}" --profile core --profile services --profile projects restart
        echo ""
        echo "✅ All services restarted successfully!"
        ;;

    ps)
        docker compose "${COMPOSE_FILES[@]}" ps
        ;;

    logs)
        docker compose "${COMPOSE_FILES[@]}" logs -f "$@"
        ;;



    install)
        sudo bash "$CLI_DIR/commands/install.sh"
        ;;

    uninstall)
        sudo bash "$CLI_DIR/commands/uninstall.sh"
        ;;

    pull)
        bash "$CLI_DIR/commands/pull.sh"
        ;;

    *)
        echo "Stackvo CLI"
        echo ""
        echo "Available commands:"
        echo "  stackvo install               → install Stackvo CLI"
        echo "  stackvo generate              → generate dynamic compose (all)"
        echo "  stackvo generate projects     → generate only projects"
        echo "  stackvo generate services     → generate only services"
        echo "  stackvo up                    → start core services (minimal)"
        echo "  stackvo up --services         → start core + all services"
        echo "  stackvo up --projects         → start core + all projects"
        echo "  stackvo up --all              → start everything (old behavior)"
        echo "  stackvo up --profile <name>   → start core + specific profile"
        echo "  stackvo down                  → stop the system"
        echo "  stackvo restart               → restart services"
        echo "  stackvo ps                    → list running services"
        echo "  stackvo logs [srv]            → follow logs"
        echo "  stackvo pull                  → pull Docker images"

        echo "  stackvo uninstall             → uninstall Stackvo (removes all Docker resources and files)"
        echo ""
        echo "Examples:"
        echo "  stackvo up                    → Start only Traefik + UI"
        echo "  stackvo up --profile mysql    → Start core + MySQL only"
        echo "  stackvo up --profile project-myproject  → Start core + myproject only"
        echo ""
        exit 1
        ;;
esac
