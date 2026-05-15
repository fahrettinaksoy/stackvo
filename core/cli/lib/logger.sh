#!/bin/bash
###################################################################
# STACKVO LOGGER LIBRARY
# Common logging functions - used in all scripts
###################################################################

# Colors - made constant with readonly
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'  # No Color

# Verbosity:
#   STACKVO_VERBOSE=1  -> show [INFO] and [DEBUG] (everything)
#   default            -> only [WARN], [ERROR] and [OK] milestones
# log_warn / log_error are always shown.

log_info() {
    [ "${STACKVO_VERBOSE:-0}" = "1" ] && echo -e "${BLUE}[INFO]${NC} $1" >&2
    return 0
}

log_debug() {
    [ "${STACKVO_VERBOSE:-0}" = "1" ] && echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    return 0
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# UI helpers — visual structure for command output

print_banner() {
    local title="$1"
    local subtitle="$2"
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║${NC}  ${GREEN}%-60s${NC} ${BLUE}║${NC}\n" "$title"
    if [ -n "$subtitle" ]; then
        printf "${BLUE}║${NC}  %-60s ${BLUE}║${NC}\n" "$subtitle"
    fi
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}── $1 ${NC}"
    echo ""
}

##
# Verilen PID bitene kadar mesajla birlikte braille spinner gösterir.
# Süreç tamamlanınca satırı temizleyip sürecin exit kodunu döndürür.
# Kullanım:
#   long_running_cmd &
#   wait_with_spinner $! "Yükleniyor..."
##
wait_with_spinner() {
    local pid=$1
    local msg=$2
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    local delay=0.1

    tput civis 2>/dev/null
    trap 'tput cnorm 2>/dev/null' EXIT

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${BLUE}%s${NC} %s" "${frames[i]}" "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep "$delay"
    done

    tput cnorm 2>/dev/null
    printf "\r\033[K"

    wait "$pid" 2>/dev/null
    return $?
}

print_done_box() {
    local title="$1"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    printf "${GREEN}║${NC}  ${GREEN}✓ %-58s${NC} ${GREEN}║${NC}\n" "$title"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
}
