#!/bin/bash
###################################################################
# Stackvo SSL Certificate Generator with mkcert
# Generates trusted SSL certificates for local development
# Auto-installs mkcert if not present
###################################################################

set -eo pipefail

# Global constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# CLI is in core/cli/, utils is in core/cli/utils/, so go up 3 levels to reach stackvo root
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
readonly CERT_DIR="$ROOT_DIR/generated/certs"

# Load logger library
source "$SCRIPT_DIR/../lib/logger.sh"
source "$SCRIPT_DIR/../lib/permissions.sh"

# Check if mkcert is installed, install if not
validate_mkcert() {
    if command -v mkcert &> /dev/null; then
        log_success "mkcert is already installed"
        return 0
    fi
    
    log_warn "mkcert is not installed. Installing automatically..."
    
    # Detect OS
    local os_type=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
    else
        log_error "Unsupported OS: $OSTYPE"
        echo "Please install mkcert manually from: https://github.com/FiloSottile/mkcert" >&2
        exit 1
    fi
    
    if [ "$os_type" = "linux" ]; then
        log_info "Installing mkcert for Linux..."
        
        # Install dependencies
        if command -v apt-get &> /dev/null; then
            log_info "Installing libnss3-tools..."
            sudo apt-get update -qq
            sudo apt-get install -y libnss3-tools
        elif command -v yum &> /dev/null; then
            log_info "Installing nss-tools..."
            sudo yum install -y nss-tools
        fi
        
        # Download and install mkcert
        local mkcert_version="v1.4.4"
        local mkcert_url="https://github.com/FiloSottile/mkcert/releases/download/${mkcert_version}/mkcert-${mkcert_version}-linux-amd64"
        
        log_info "Downloading mkcert ${mkcert_version}..."
        wget -q "$mkcert_url" -O /tmp/mkcert
        
        log_info "Installing to /usr/local/bin/mkcert..."
        sudo mv /tmp/mkcert /usr/local/bin/mkcert
        sudo chmod +x /usr/local/bin/mkcert
        
        log_success "mkcert installed successfully!"
        
    elif [ "$os_type" = "macos" ]; then
        log_info "Installing mkcert for macOS..."
        
        if command -v brew &> /dev/null; then
            # Check if running as root (via sudo)
            if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
                log_info "Running as sudo, switching to user $SUDO_USER for Homebrew..."
                # Run brew as the actual user, not root (suppress verbose output)
                if su - "$SUDO_USER" -c "HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 brew install mkcert" > /dev/null 2>&1; then
                    log_success "mkcert installed successfully!"
                else
                    log_error "Failed to install mkcert via Homebrew"
                    exit 1
                fi
            else
                # Normal user execution (suppress verbose output)
                HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 brew install mkcert > /dev/null 2>&1
                log_success "mkcert installed successfully!"
            fi
        else
            log_error "Homebrew is not installed. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" >&2
            exit 1
        fi
    fi
    
    # Install CA (suppress verbose output)
    log_info "Installing mkcert CA to system trust store..."
    mkcert -install > /dev/null 2>&1
    
    log_success "✅ mkcert setup completed!"
}

# Collect all domains from projects
get_project_domains() {
    local domains=()
    
    # Base domains
    domains+=("stackvo.loc")
    domains+=("*.stackvo.loc")
    
    # Scan projects directory for stackvo.json files
    if [ -d "$ROOT_DIR/projects" ]; then
        for project_path in "$ROOT_DIR/projects"/*; do
            [ ! -d "$project_path" ] && continue
            
            local project_json="$project_path/stackvo.json"
            [ ! -f "$project_json" ] && continue
            
            # Extract domain from JSON
            local domain=$(grep -o '"domain"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" | cut -d'"' -f4)
            
            if [ -n "$domain" ]; then
                domains+=("$domain")
            fi
        done
    fi
    
    # Return domains as space-separated string
    echo "${domains[@]}"
}

# Trust CA in macOS login keychain (no sudo required)
trust_ca_in_keychain() {
    local ca_pem="$1"

    [[ "$OSTYPE" != "darwin"* ]] && return 0
    [ ! -f "$ca_pem" ] && return 0

    # Get fingerprint of our CA
    local our_fingerprint=$(openssl x509 -in "$ca_pem" -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//')
    [ -z "$our_fingerprint" ] && return 1

    # Check if THIS specific CA is already in the keychain (by fingerprint)
    local keychain_fingerprint=$(security find-certificate -c "mkcert" -p ~/Library/Keychains/login.keychain-db 2>/dev/null \
        | openssl x509 -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//')

    if [ "$our_fingerprint" = "$keychain_fingerprint" ]; then
        return 0
    fi

    # Remove old mkcert CA from keychain if it exists (different fingerprint)
    if [ -n "$keychain_fingerprint" ]; then
        log_info "Replacing old mkcert CA in keychain..."
        security delete-certificate -c "mkcert" ~/Library/Keychains/login.keychain-db 2>/dev/null || true
    fi

    log_info "Adding CA to macOS login keychain..."
    if security add-trusted-cert -k ~/Library/Keychains/login.keychain-db "$ca_pem" 2>/dev/null; then
        log_success "CA trusted in login keychain"
    else
        log_warn "Could not add CA to keychain. Run 'sudo mkcert -install' to trust certificates in your browser"
    fi
}

# Ensure mkcert CA is accessible, use fallback CAROOT if needed
ensure_caroot_access() {
    local default_caroot=$(mkcert -CAROOT 2>/dev/null)

    # Check if default CA key is readable
    if [ -n "$default_caroot" ] && [ -r "$default_caroot/rootCA-key.pem" ]; then
        trust_ca_in_keychain "$default_caroot/rootCA.pem"
        return 0
    fi

    # Default CA key not readable (likely owned by root from sudo install)
    # Use a fallback CAROOT in ~/.stackvo/ca/ (persists across uninstall)
    local fallback_caroot="$HOME/.stackvo/ca"

    if [ -r "$fallback_caroot/rootCA-key.pem" ]; then
        log_info "Using existing fallback CA from $fallback_caroot"
        export CAROOT="$fallback_caroot"
        trust_ca_in_keychain "$fallback_caroot/rootCA.pem"
        return 0
    fi

    log_warn "Default mkcert CA is not accessible (permission denied). Creating a new CA..."
    mkdir -p "$fallback_caroot"
    export CAROOT="$fallback_caroot"

    # Create new CA (trust store installation may fail without sudo, that's OK)
    mkcert -install 2>/dev/null || true

    if [ -r "$fallback_caroot/rootCA-key.pem" ]; then
        log_success "Fallback CA created at $fallback_caroot"
        trust_ca_in_keychain "$fallback_caroot/rootCA.pem"
    else
        log_error "Failed to create fallback CA"
        return 1
    fi
}

# Generate certificates with mkcert
generate_certificates() {
    log_info "🔐 Generating SSL Certificates with mkcert..."

    # Create cert directory
    mkdir -p "$CERT_DIR"

    # Fix permissions using centralized function
    fix_directory_permissions "$ROOT_DIR/generated"

    # Ensure CA is accessible
    ensure_caroot_access

    # Collect all domains
    local domains=($(get_project_domains))

    if [ ${#domains[@]} -eq 0 ]; then
        log_error "No domains found!"
        exit 1
    fi

    log_info "Generating certificates for ${#domains[@]} domain(s)..."

    # Generate certificate with mkcert (suppress verbose output)
    cd "$CERT_DIR"

    # Remove old certificates
    rm -f stackvo-wildcard.crt stackvo-wildcard.key

    # Generate new certificate for all domains (suppress output)
    if ! mkcert -cert-file stackvo-wildcard.crt \
           -key-file stackvo-wildcard.key \
           "${domains[@]}" > /dev/null 2>&1; then
        log_error "Failed to generate SSL certificates with mkcert"
        cd "$ROOT_DIR"
        exit 1
    fi

    # Copy CA certificate for reference
    local ca_location=$(mkcert -CAROOT)
    if [ -f "$ca_location/rootCA.pem" ]; then
        cp "$ca_location/rootCA.pem" "$CERT_DIR/stackvo-ca.crt"
    fi

    cd "$ROOT_DIR"

    log_success "✅ SSL Certificates generated successfully!"
}

# Display certificate info
show_certificate_info() {
    echo "" >&2
    echo "📁 Certificate files created:" >&2
    echo "   - stackvo-wildcard.crt (SSL Certificate)" >&2
    echo "   - stackvo-wildcard.key (Private Key)" >&2
    echo "   - stackvo-ca.crt (CA Certificate)" >&2
    echo "" >&2
    
    log_success "📌 Certificates are trusted by your system!"
    echo "" >&2
}

# Main
main() {
    echo "🔐 Stackvo SSL Certificate Generator (mkcert)" >&2
    echo "" >&2
    
    validate_mkcert
    generate_certificates
    show_certificate_info
}

main "$@"
