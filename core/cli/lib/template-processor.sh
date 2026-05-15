#!/bin/bash
###################################################################
# STACKVO TEMPLATE PROCESSOR MODULE
# Template rendering and module inclusion
###################################################################

##
# Renders template file ({{ VAR }} → ${VAR} conversion)
#
# Arguments:
#   $1 - Template file path
#
# Returns:
#   0 - Success
#   1 - Template file not found
##
render_template() {
    local template_file=$1
    
    if [ ! -f "$template_file" ]; then
        log_error "Template file not found: $template_file"
        return 1
    fi
    
    # Use Perl for template rendering to avoid dependency on envsubst (which is not on macOS by default)
    # This logic replicates the original sed + envsubst pipeline:
    # 1. Matches {{ VAR }} and {{ VAR | default('val') }}
    # 2. Checks if VAR matches allowed prefixes (STACKVO_, SERVICE_, etc.)
    # 3. If matched: replaces with ENV value (or default, or empty)
    # 4. If not matched: preserves as ${VAR} or ${VAR:-default} for later expansion
    
    perl -e 'use strict; use warnings; my $file = $ARGV[0]; open(my $fh, "<", $file) or die "Cannot open $file: $!"; my $regex = qr/^(STACKVO_|SERVICE_|DEFAULT_|DOCKER_|TLD_|HOST_|SSL_|REDIRECT_)/; while (my $line = <$fh>) { $line =~ s/\{\{\s*([A-Z0-9_]+)\s*(?:\|\s*default\((["'"'"'])(.*?)\2\))?\s*\}\}/ my $var = $1; my $def = $3; if ($var =~ $regex) { if (defined $ENV{$var}) { $ENV{$var}; } elsif (defined $def) { $def; } else { ""; } } else { if (defined $def) { "\${$var:-$def}"; } else { "\${$var}"; } } /ge; $line =~ s/\$\{([A-Z0-9_]+)\}/ my $var = $1; if ($var =~ $regex) { defined($ENV{$var}) ? $ENV{$var} : ""; } else { "\${$var}"; } /ge; $line =~ s/(?<!\{)\$([A-Z0-9_]+)/ my $var = $1; if ($var =~ $regex) { defined($ENV{$var}) ? $ENV{$var} : ""; } else { "\$$var"; } /ge; print $line; } close($fh);' "$template_file"
    
    if [ $? -ne 0 ]; then
        log_error "Failed to render template: $template_file"
        return 1
    fi
}

##
# Processes module template and adds to compose file (if enabled)
#
# Arguments:
#   $1 - Enable variable name (e.g., MYSQL_ENABLE)
#   $2 - Template file path (e.g., database/mysql/docker-compose.mysql.tpl)
#
# Returns:
#   0 - Success or disabled
#   1 - Template not found
##
include_module() {
    local enable_var=$1
    local template_path=$2
    local full_path="$ROOT_DIR/core/templates/$template_path"
    
    # Check if enabled
    eval "local enabled=\${${enable_var}:-false}"
    
    if [ "$enabled" = "true" ]; then
        if [ ! -f "$full_path" ]; then
            log_warn "Template not found for $enable_var: $full_path"
            return 1
        fi
        
        log_info "Including: $enable_var"
        
        # Process template and extract only service definitions
        # Skip: comments (#), "services:" line, "volumes:" section
        # Fix: indentation for ports/networks and their list items
        local rendered_output
        rendered_output=$(render_template "$full_path")
        
        if [ $? -ne 0 ] || [ -z "$rendered_output" ]; then
            log_error "Failed to render template for $enable_var"
            return 1
        fi
        
        echo "$rendered_output" | \
            awk '
                /^#/ { next }                      # Skip ALL comment lines
                /^services:/ { next }              # Skip services header  
                /^volumes:/ { in_volumes=1 }       # Mark volumes section
                in_volumes { next }                # Skip volumes section
                /^[[:space:]]*$/ && !started { next }  # Skip leading blank lines
                
                # Track ports/networks sections
                /^ports:/ { 
                    print "    ports:"
                    in_ports=1
                    next
                }
                /^networks:/ { 
                    print "    networks:"
                    in_networks=1
                    next
                }
                
                # Reset section tracking when we hit a new top-level key
                /^[a-z_]+:/ && !/^  / { 
                    in_ports=0
                    in_networks=0
                }
                
                # Indent list items in ports/networks sections
                in_ports && /^- / { 
                    sub(/^- /, "      - ")
                    print
                    next
                }
                in_networks && /^- / { 
                    sub(/^- /, "      - ")
                    print
                    next
                }
                
                { started=1; print }               # Print everything else
            '
        
        echo ""
    fi
}
