#!/bin/bash
#
# macOS Server Optimisation Script
# Transforms macOS Sequoia into a high-performance server environment
#
# Usage: ./optimise.sh [OPTIONS]
#
# Options:
#   --dry-run           Preview changes without applying them
#   --verbose           Show detailed output
#   --yes               Skip confirmation prompts (except conditional services)
#   --category=LIST     Apply only specific categories (comma-separated)
#                       Categories: telemetry,siri,analysis,consumer,media,sharing,
#                                   icloud,backup,bluetooth,network,power,defaults,spotlight
#   --skip-backup       Skip creating backup before changes
#   --help              Show this help message
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_DIR="${SCRIPT_DIR}/backups"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
LOG_FILE="${LOG_DIR}/optimisation_${TIMESTAMP}.log"

# Script version
VERSION="1.0.0"

# Current user ID
CURRENT_UID=$(id -u)

# ============================================================================
# COLOUR DEFINITIONS
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

# ============================================================================
# DEFAULT OPTIONS
# ============================================================================
DRY_RUN=false
VERBOSE=false
YES_MODE=false
SKIP_BACKUP=false
SELECTED_CATEGORIES=""

# Conditional service decisions (will be prompted if not using --yes)
DISABLE_ICLOUD=""
DISABLE_BACKUP=""
DISABLE_BLUETOOTH=""

# Counters
CHANGES_MADE=0
CHANGES_SKIPPED=0
ERRORS_ENCOUNTERED=0

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
log_info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}${msg}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${LOG_FILE}"
}

log_success() {
    local msg="[SUCCESS] $1"
    echo -e "${GREEN}${msg}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${LOG_FILE}"
}

log_warning() {
    local msg="[WARNING] $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${LOG_FILE}"
}

log_error() {
    local msg="[ERROR] $1"
    echo -e "${RED}${msg}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${LOG_FILE}"
    ((ERRORS_ENCOUNTERED++)) || true
}

log_step() {
    local msg="[STEP] $1"
    echo -e "${CYAN}${msg}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${LOG_FILE}"
}

log_verbose() {
    if [[ "${VERBOSE}" == "true" ]]; then
        local msg="[VERBOSE] $1"
        echo -e "${MAGENTA}${msg}${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${LOG_FILE}"
    fi
}

log_dry_run() {
    local msg="[DRY-RUN] Would execute: $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${LOG_FILE}"
}

print_header() {
    echo ""
    echo -e "${BOLD}============================================================================${NC}"
    echo -e "${BOLD} $1${NC}"
    echo -e "${BOLD}============================================================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
    echo ""
}

# Ask yes/no question
ask_yes_no() {
    local prompt="$1"
    local default="${2:-}"

    if [[ "${YES_MODE}" == "true" && -n "${default}" ]]; then
        echo "${default}"
        return
    fi

    while true; do
        read -r -p "${prompt} [y/n]: " answer
        case "${answer}" in
            [Yy]* ) echo "yes"; return;;
            [Nn]* ) echo "no"; return;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Check if category is selected
is_category_selected() {
    local category="$1"

    # If no categories specified, all are selected
    if [[ -z "${SELECTED_CATEGORIES}" ]]; then
        return 0
    fi

    # Check if category is in the comma-separated list
    if [[ ",${SELECTED_CATEGORIES}," == *",${category},"* ]]; then
        return 0
    fi

    return 1
}

# Execute command or dry-run
execute() {
    local cmd="$1"
    local description="${2:-}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_dry_run "${cmd}"
        return 0
    fi

    log_verbose "Executing: ${cmd}"
    if eval "${cmd}" 2>> "${LOG_FILE}"; then
        if [[ -n "${description}" ]]; then
            log_success "${description}"
        fi
        ((CHANGES_MADE++)) || true
        return 0
    else
        if [[ -n "${description}" ]]; then
            log_error "Failed: ${description}"
        fi
        return 1
    fi
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --yes|-y)
                YES_MODE=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --category=*)
                SELECTED_CATEGORIES="${1#*=}"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
macOS Server Optimisation Script v1.0.0

Usage: ./optimise.sh [OPTIONS]

Optimises macOS Sequoia 15.7.3 for high-performance server workloads by
disabling unnecessary consumer services, tuning the network stack, and
configuring power management for 24/7 operation.

OPTIONS:
  --dry-run           Preview all changes without applying them
  --verbose           Show detailed output including all commands
  --yes, -y           Skip confirmation prompts (conditional services still prompt)
  --skip-backup       Skip creating backup before changes (not recommended)
  --category=LIST     Apply only specific categories (comma-separated)
  --help, -h          Show this help message

CATEGORIES:
  telemetry    Analytics and diagnostic services (always safe)
  siri         Siri and voice assistant services
  analysis     Photo/media analysis (highest CPU savings)
  consumer     Game Center, Screen Time, Maps, etc.
  media        AirPlay, Music, iTunes cloud
  sharing      AirDrop, Handoff, Sidecar
  icloud       iCloud sync services (prompted)
  backup       Time Machine (prompted)
  bluetooth    Bluetooth services (prompted)
  network      TCP/IP stack tuning
  power        Power management settings
  defaults     macOS preferences (crash reporter, updates, etc.)
  spotlight    Spotlight indexing

EXAMPLES:
  # Preview all changes without applying
  ./optimise.sh --dry-run

  # Apply only telemetry and analysis optimisations
  ./optimise.sh --category=telemetry,analysis

  # Apply all changes with verbose output, skip confirmations
  ./optimise.sh --verbose --yes

  # Full optimisation with backup
  ./optimise.sh --verbose

SAFETY:
  - All changes are reversible using ./restore.sh
  - A full backup is created before any changes (unless --skip-backup)
  - Critical system services are NEVER modified
  - SIP must be disabled for some optimisations

EOF
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================
preflight_checks() {
    print_header "Pre-flight Checks"

    local checks_passed=true

    # Check if running as admin (not root, but with sudo access)
    log_step "Checking admin privileges..."
    if sudo -n true 2>/dev/null; then
        log_success "Admin privileges available"
    else
        log_warning "Will need to enter password for some operations"
    fi

    # Check macOS version
    log_step "Checking macOS version..."
    local macos_version
    macos_version=$(sw_vers -productVersion)
    if [[ "${macos_version}" == 15.* ]]; then
        log_success "macOS ${macos_version} (Sequoia) detected"
    else
        log_warning "This script is designed for macOS 15.x (Sequoia). Detected: ${macos_version}"
        log_warning "Some optimisations may not work as expected"
    fi

    # Check SIP status
    log_step "Checking System Integrity Protection..."
    local sip_status
    sip_status=$(csrutil status 2>/dev/null || echo "unknown")
    if [[ "${sip_status}" == *"disabled"* ]]; then
        log_success "SIP is disabled - full optimisation available"
    else
        log_warning "SIP is enabled - some service disabling may not persist"
        log_warning "To disable SIP: Boot to Recovery Mode > Terminal > csrutil disable"
    fi

    # Check disk space
    log_step "Checking disk space..."
    local free_space
    free_space=$(df -g / | awk 'NR==2 {print $4}')
    if [[ "${free_space}" -gt 1 ]]; then
        log_success "Sufficient disk space available (${free_space}GB free)"
    else
        log_warning "Low disk space (${free_space}GB free)"
    fi

    # Check if config files exist
    log_step "Checking configuration files..."
    if [[ -f "${CONFIG_DIR}/services.conf" && -f "${CONFIG_DIR}/sysctl.conf" && -f "${CONFIG_DIR}/defaults.conf" ]]; then
        log_success "All configuration files found"
    else
        log_error "Missing configuration files in ${CONFIG_DIR}"
        checks_passed=false
    fi

    # Check server performance mode
    log_step "Checking server performance mode..."
    local boot_args
    boot_args=$(nvram boot-args 2>/dev/null | cut -f2 || echo "")
    if [[ "${boot_args}" == *"serverperfmode=1"* ]]; then
        log_success "Server performance mode is already enabled"
    else
        log_info "Server performance mode not enabled (will be configured)"
    fi

    echo ""
    if [[ "${checks_passed}" == "false" ]]; then
        log_error "Pre-flight checks failed. Please fix issues before continuing."
        exit 1
    fi

    log_success "All pre-flight checks passed"
}

# ============================================================================
# CONDITIONAL SERVICE PROMPTS
# ============================================================================
prompt_conditional_services() {
    print_header "Conditional Services Configuration"

    echo "The following services can be disabled but may affect functionality."
    echo "Please review each carefully before deciding."
    echo ""

    # ========================================================================
    # iCLOUD SERVICES
    # ========================================================================
    if is_category_selected "icloud" || [[ -z "${SELECTED_CATEGORIES}" ]]; then
        print_section "iCloud Services"

        echo -e "${BOLD}What will stop working if disabled:${NC}"
        echo "  - iCloud Drive sync (Desktop, Documents, Downloads)"
        echo "  - iCloud Photos sync"
        echo "  - iCloud Keychain sync"
        echo "  - Find My Mac (device location)"
        echo "  - Handoff between devices"
        echo "  - iCloud Backup coordination"
        echo "  - Safari bookmark/history sync"
        echo "  - Notes, Reminders, Contacts sync"
        echo ""
        echo -e "${BOLD}When you SHOULD disable:${NC}"
        echo "  - This is a dedicated server with no user data"
        echo "  - You're not using any Apple services on this machine"
        echo "  - You're running containerised workloads (Docker, etc.)"
        echo "  - Privacy/security requires no cloud connectivity"
        echo ""
        echo -e "${BOLD}When you should KEEP enabled:${NC}"
        echo "  - You use this Mac for development AND personal use"
        echo "  - You need Find My Mac for theft protection"
        echo "  - You sync any data with other Apple devices"
        echo ""

        DISABLE_ICLOUD=$(ask_yes_no "Disable iCloud services?" "")
        echo ""
    fi

    # ========================================================================
    # TIME MACHINE / BACKUP
    # ========================================================================
    if is_category_selected "backup" || [[ -z "${SELECTED_CATEGORIES}" ]]; then
        print_section "Time Machine / Backup Services"

        echo -e "${BOLD}What will stop working if disabled:${NC}"
        echo "  - Time Machine automatic backups"
        echo "  - Local snapshots (for quick file recovery)"
        echo "  - Time Machine to network destinations"
        echo "  - APFS snapshot management via Time Machine"
        echo ""
        echo -e "${BOLD}When you SHOULD disable:${NC}"
        echo "  - You use alternative backup (Veeam, rsync, ZFS, etc.)"
        echo "  - Server data is backed up at infrastructure level"
        echo "  - Running in VM/container with external backup"
        echo "  - You have separate backup strategy for this machine"
        echo ""
        echo -e "${BOLD}When you should KEEP enabled:${NC}"
        echo "  - Time Machine is your only backup"
        echo "  - You regularly restore files from Time Machine"
        echo "  - No other backup solution is in place"
        echo ""

        DISABLE_BACKUP=$(ask_yes_no "Disable Time Machine services?" "")
        echo ""
    fi

    # ========================================================================
    # BLUETOOTH
    # ========================================================================
    if is_category_selected "bluetooth" || [[ -z "${SELECTED_CATEGORIES}" ]]; then
        print_section "Bluetooth Services"

        echo -e "${BOLD}What will stop working if disabled:${NC}"
        echo "  - Bluetooth keyboard/mouse/trackpad"
        echo "  - AirPods and Bluetooth headphones"
        echo "  - Bluetooth file transfer"
        echo "  - Continuity features (Universal Clipboard, etc.)"
        echo "  - HandOff between devices"
        echo ""
        echo -e "${BOLD}When you SHOULD disable:${NC}"
        echo "  - Mac mini in rack/closet with only wired peripherals"
        echo "  - Headless server accessed only via SSH/VNC"
        echo "  - Security policy requires Bluetooth disabled"
        echo "  - No Bluetooth devices are ever connected"
        echo ""
        echo -e "${BOLD}When you should KEEP enabled:${NC}"
        echo "  - You use Bluetooth keyboard or mouse"
        echo "  - You connect AirPods or speakers"
        echo "  - You use Universal Clipboard with iPhone/iPad"
        echo "  - Physical access to machine uses BT peripherals"
        echo ""

        DISABLE_BLUETOOTH=$(ask_yes_no "Disable Bluetooth services?" "")
        echo ""
    fi
}

# ============================================================================
# DISABLE SERVICES
# ============================================================================
disable_services() {
    print_header "Disabling Services"

    local services_file="${CONFIG_DIR}/services.conf"

    if [[ ! -f "${services_file}" ]]; then
        log_error "Services configuration file not found: ${services_file}"
        return 1
    fi

    # Read and process services file
    while IFS='|' read -r domain service category description; do
        # Skip comments and empty lines
        [[ "${domain}" =~ ^#.*$ || -z "${domain}" ]] && continue

        # Trim whitespace
        domain=$(echo "${domain}" | xargs)
        service=$(echo "${service}" | xargs)
        category=$(echo "${category}" | xargs)
        description=$(echo "${description}" | xargs)

        # Check if category is selected
        if ! is_category_selected "${category}"; then
            log_verbose "Skipping ${service} (category '${category}' not selected)"
            continue
        fi

        # Handle conditional categories
        case "${category}" in
            icloud)
                if [[ "${DISABLE_ICLOUD}" != "yes" ]]; then
                    log_verbose "Skipping ${service} (iCloud services kept)"
                    continue
                fi
                ;;
            backup)
                if [[ "${DISABLE_BACKUP}" != "yes" ]]; then
                    log_verbose "Skipping ${service} (backup services kept)"
                    continue
                fi
                ;;
            bluetooth)
                if [[ "${DISABLE_BLUETOOTH}" != "yes" ]]; then
                    log_verbose "Skipping ${service} (Bluetooth services kept)"
                    continue
                fi
                ;;
        esac

        # Build the launchctl command based on domain
        local disable_cmd=""
        local bootout_cmd=""

        case "${domain}" in
            system)
                disable_cmd="sudo launchctl disable system/${service}"
                bootout_cmd="sudo launchctl bootout system/${service} 2>/dev/null || true"
                ;;
            user)
                disable_cmd="launchctl disable user/${CURRENT_UID}/${service}"
                bootout_cmd="launchctl bootout user/${CURRENT_UID}/${service} 2>/dev/null || true"
                ;;
            gui)
                disable_cmd="launchctl disable gui/${CURRENT_UID}/${service}"
                bootout_cmd="launchctl bootout gui/${CURRENT_UID}/${service} 2>/dev/null || true"
                ;;
            *)
                log_warning "Unknown domain '${domain}' for service ${service}"
                continue
                ;;
        esac

        # Log what we're doing
        log_info "Disabling: ${service} (${description})"

        # Execute the disable command
        if execute "${disable_cmd}" "Disabled ${service}"; then
            # Also bootout the service if currently running
            execute "${bootout_cmd}" "" || true
        else
            ((CHANGES_SKIPPED++)) || true
        fi

    done < "${services_file}"
}

# ============================================================================
# APPLY SYSCTL SETTINGS
# ============================================================================
apply_sysctl_settings() {
    if ! is_category_selected "network"; then
        log_verbose "Skipping network/sysctl settings (category not selected)"
        return 0
    fi

    print_header "Applying Network Stack Tuning"

    local sysctl_file="${CONFIG_DIR}/sysctl.conf"

    if [[ ! -f "${sysctl_file}" ]]; then
        log_error "Sysctl configuration file not found: ${sysctl_file}"
        return 1
    fi

    # Read and apply each setting
    while IFS='=' read -r param value; do
        # Skip comments and empty lines
        [[ "${param}" =~ ^#.*$ || -z "${param}" ]] && continue

        # Trim whitespace
        param=$(echo "${param}" | xargs)
        value=$(echo "${value}" | xargs)

        # Skip if empty
        [[ -z "${param}" || -z "${value}" ]] && continue

        # Get current value
        local current_value
        current_value=$(sysctl -n "${param}" 2>/dev/null || echo "unknown")

        if [[ "${current_value}" == "${value}" ]]; then
            log_verbose "Already set: ${param}=${value}"
            continue
        fi

        log_info "Setting ${param}: ${current_value} -> ${value}"
        execute "sudo sysctl -w ${param}=${value}" "Applied ${param}=${value}"

    done < "${sysctl_file}"

    # Create persistent sysctl.conf if it doesn't exist
    if [[ "${DRY_RUN}" != "true" ]]; then
        log_step "Creating persistent sysctl configuration..."

        # The settings need to be applied at boot via LaunchDaemon
        local sysctl_plist="/Library/LaunchDaemons/com.server.sysctl.plist"

        if [[ ! -f "${sysctl_plist}" ]]; then
            log_info "Creating sysctl LaunchDaemon for persistent settings"

            sudo tee "${sysctl_plist}" > /dev/null << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.server.sysctl</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>/usr/sbin/sysctl -w net.inet.tcp.mssdflt=1460 net.inet.tcp.win_scale_factor=8 net.inet.tcp.sendspace=1048576 net.inet.tcp.recvspace=1048576 net.inet.tcp.autorcvbufmax=33554432 net.inet.tcp.autosndbufmax=33554432 net.inet.tcp.delayed_ack=0 net.inet.tcp.sack=1 net.inet.tcp.always_keepalive=1 net.inet.tcp.slowstart_flightsize=20 net.inet.tcp.local_slowstart_flightsize=20 net.inet.tcp.msl=5000 net.inet.tcp.blackhole=2 net.inet.udp.blackhole=1 kern.ipc.maxsockbuf=16777216</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST_EOF

            sudo chown root:wheel "${sysctl_plist}"
            sudo chmod 644 "${sysctl_plist}"
            sudo launchctl load "${sysctl_plist}" 2>/dev/null || true

            log_success "Created persistent sysctl configuration"
            ((CHANGES_MADE++)) || true
        else
            log_verbose "sysctl LaunchDaemon already exists"
        fi
    fi
}

# ============================================================================
# APPLY DEFAULTS SETTINGS
# ============================================================================
apply_defaults_settings() {
    if ! is_category_selected "defaults"; then
        log_verbose "Skipping defaults settings (category not selected)"
        return 0
    fi

    print_header "Applying macOS Preferences"

    local defaults_file="${CONFIG_DIR}/defaults.conf"

    if [[ ! -f "${defaults_file}" ]]; then
        log_error "Defaults configuration file not found: ${defaults_file}"
        return 1
    fi

    # Read and apply each setting
    while IFS='|' read -r domain key type value description; do
        # Skip comments and empty lines
        [[ "${domain}" =~ ^#.*$ || -z "${domain}" ]] && continue

        # Trim whitespace
        domain=$(echo "${domain}" | xargs)
        key=$(echo "${key}" | xargs)
        type=$(echo "${type}" | xargs)
        value=$(echo "${value}" | xargs)
        description=$(echo "${description}" | xargs)

        # Skip if essential fields are empty
        [[ -z "${domain}" || -z "${key}" || -z "${type}" ]] && continue

        # Build the defaults command
        local defaults_cmd=""
        case "${type}" in
            bool)
                defaults_cmd="defaults write ${domain} '${key}' -bool ${value}"
                ;;
            int)
                defaults_cmd="defaults write ${domain} '${key}' -int ${value}"
                ;;
            float)
                defaults_cmd="defaults write ${domain} '${key}' -float ${value}"
                ;;
            string)
                defaults_cmd="defaults write ${domain} '${key}' -string '${value}'"
                ;;
            array)
                if [[ "${value}" == "[]" ]]; then
                    defaults_cmd="defaults write ${domain} '${key}' -array"
                else
                    defaults_cmd="defaults write ${domain} '${key}' -array ${value}"
                fi
                ;;
            *)
                log_warning "Unknown type '${type}' for ${domain} ${key}"
                continue
                ;;
        esac

        log_info "Setting: ${domain} ${key} (${description})"
        execute "${defaults_cmd}" "Applied ${key}"

    done < "${defaults_file}"

    # Kill affected processes to apply changes
    if [[ "${DRY_RUN}" != "true" ]]; then
        log_step "Restarting affected processes..."
        killall Dock 2>/dev/null || true
        killall Finder 2>/dev/null || true
        killall SystemUIServer 2>/dev/null || true
    fi
}

# ============================================================================
# APPLY POWER SETTINGS
# ============================================================================
apply_power_settings() {
    if ! is_category_selected "power"; then
        log_verbose "Skipping power settings (category not selected)"
        return 0
    fi

    print_header "Applying Power Management Settings"

    # Power Nap
    log_info "Disabling Power Nap..."
    execute "sudo pmset -a powernap 0" "Disabled Power Nap"

    # Proximity Wake
    log_info "Disabling proximity wake..."
    execute "sudo pmset -a proximitywake 0" "Disabled proximity wake"

    # Auto power off
    log_info "Disabling auto power off..."
    execute "sudo pmset -a autopoweroff 0" "Disabled auto power off"

    # Ensure sleep is disabled
    log_info "Confirming sleep is disabled..."
    execute "sudo pmset -a sleep 0" "Confirmed sleep disabled"
    execute "sudo pmset -a disksleep 0" "Confirmed disk sleep disabled"
    execute "sudo pmset -a displaysleep 0" "Confirmed display sleep disabled"

    # Enable auto restart on power failure
    log_info "Enabling auto restart on power failure..."
    execute "sudo pmset -a autorestart 1" "Enabled auto restart"

    # Wake on LAN
    log_info "Ensuring Wake on LAN is enabled..."
    execute "sudo pmset -a womp 1" "Enabled Wake on LAN"

    # TCP keepalive during sleep (for server, we don't sleep, but just in case)
    log_info "Enabling TCP keepalive..."
    execute "sudo pmset -a tcpkeepalive 1" "Enabled TCP keepalive"
}

# ============================================================================
# CONFIGURE SPOTLIGHT
# ============================================================================
configure_spotlight() {
    if ! is_category_selected "spotlight"; then
        log_verbose "Skipping Spotlight configuration (category not selected)"
        return 0
    fi

    print_header "Configuring Spotlight"

    echo -e "${BOLD}Spotlight Indexing Impact:${NC}"
    echo "  - Spotlight indexing can consume significant CPU and disk I/O"
    echo "  - For servers, local search is rarely needed"
    echo "  - Disabling saves resources but removes local file search capability"
    echo ""

    local disable_spotlight
    disable_spotlight=$(ask_yes_no "Disable Spotlight indexing on all volumes?" "yes")

    if [[ "${disable_spotlight}" == "yes" ]]; then
        log_info "Disabling Spotlight indexing..."
        execute "sudo mdutil -a -i off" "Disabled Spotlight indexing"

        log_info "Removing existing Spotlight index..."
        if [[ "${DRY_RUN}" != "true" ]]; then
            sudo rm -rf /.Spotlight-V100 2>/dev/null || true
            log_success "Removed Spotlight index"
        fi
    else
        log_info "Keeping Spotlight indexing enabled"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
main() {
    # Create directories
    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"

    # Initialise log file
    echo "# macOS Server Optimisation Log" > "${LOG_FILE}"
    echo "# Started: $(date)" >> "${LOG_FILE}"
    echo "# Options: DRY_RUN=${DRY_RUN}, VERBOSE=${VERBOSE}, YES_MODE=${YES_MODE}" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"

    # Show banner
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║             macOS Server Optimisation Script v${VERSION}                     ║${NC}"
    echo -e "${BOLD}║                     For macOS Sequoia 15.7.3                             ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo -e "${YELLOW}>>> DRY RUN MODE - No changes will be made <<<${NC}"
        echo ""
    fi

    if [[ -n "${SELECTED_CATEGORIES}" ]]; then
        echo -e "${CYAN}Selected categories: ${SELECTED_CATEGORIES}${NC}"
        echo ""
    fi

    # Run pre-flight checks
    preflight_checks

    # Create backup (unless skipped)
    if [[ "${SKIP_BACKUP}" != "true" && "${DRY_RUN}" != "true" ]]; then
        print_header "Creating Backup"
        log_info "Running backup script..."
        if "${SCRIPT_DIR}/backup_settings.sh" --output-dir "${BACKUP_DIR}"; then
            log_success "Backup completed"
        else
            log_error "Backup failed"
            if [[ "${YES_MODE}" != "true" ]]; then
                local continue_anyway
                continue_anyway=$(ask_yes_no "Continue without backup?" "no")
                if [[ "${continue_anyway}" != "yes" ]]; then
                    log_info "Aborting due to backup failure"
                    exit 1
                fi
            fi
        fi
    fi

    # Prompt for conditional services
    prompt_conditional_services

    # Confirmation before proceeding
    if [[ "${YES_MODE}" != "true" && "${DRY_RUN}" != "true" ]]; then
        print_section "Confirmation"
        echo "Ready to apply optimisations. This will:"
        echo "  - Disable consumer services (Siri, Game Center, Photos analysis, etc.)"
        echo "  - Tune network stack for high-performance"
        echo "  - Configure power management for 24/7 operation"
        echo "  - Modify system preferences"
        [[ "${DISABLE_ICLOUD}" == "yes" ]] && echo "  - Disable iCloud services"
        [[ "${DISABLE_BACKUP}" == "yes" ]] && echo "  - Disable Time Machine services"
        [[ "${DISABLE_BLUETOOTH}" == "yes" ]] && echo "  - Disable Bluetooth services"
        echo ""

        local proceed
        proceed=$(ask_yes_no "Proceed with optimisation?" "")
        if [[ "${proceed}" != "yes" ]]; then
            log_info "Optimisation cancelled by user"
            exit 0
        fi
    fi

    # Apply optimisations
    disable_services
    apply_sysctl_settings
    apply_defaults_settings
    apply_power_settings
    configure_spotlight

    # Summary
    print_header "Optimisation Complete"

    echo "Results:"
    echo -e "  ${GREEN}Changes applied:${NC} ${CHANGES_MADE}"
    echo -e "  ${YELLOW}Changes skipped:${NC} ${CHANGES_SKIPPED}"
    echo -e "  ${RED}Errors:${NC} ${ERRORS_ENCOUNTERED}"
    echo ""

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo "Run without --dry-run to apply changes."
    else
        echo "Log file: ${LOG_FILE}"
        echo ""
        echo -e "${BOLD}IMPORTANT:${NC} Some changes require a restart to take full effect."
        echo ""

        local restart_now
        restart_now=$(ask_yes_no "Restart now?" "no")
        if [[ "${restart_now}" == "yes" ]]; then
            log_info "Restarting system..."
            sudo shutdown -r now
        else
            echo ""
            echo "Remember to restart when convenient."
            echo "To restore previous settings, run:"
            echo "  ./restore.sh <backup-timestamp>"
        fi
    fi
}

# ============================================================================
# ENTRY POINT
# ============================================================================
parse_arguments "$@"
main
