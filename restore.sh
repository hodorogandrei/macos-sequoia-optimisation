#!/bin/bash
#
# macOS Server Optimisation - Restore Utility
# Restores system settings from a backup created by backup_settings.sh
#
# Usage: ./restore.sh <backup-timestamp> [OPTIONS]
#
# Example: ./restore.sh 2025-12-31_143022
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
LOG_FILE="${LOG_DIR}/restore_${TIMESTAMP}.log"
VERSION="1.1.0"

# Current user ID (use SUDO_UID if running under sudo, for GUI services)
CURRENT_UID="${SUDO_UID:-$(id -u)}"

# ============================================================================
# COLOUR DEFINITIONS
# ============================================================================
# Detect if stdout is a terminal and colours should be used
# Respects NO_COLOR environment variable (https://no-color.org/)
setup_colours() {
    if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]] && [[ "${USE_COLOR:-auto}" != "never" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        MAGENTA='\033[0;35m'
        BOLD='\033[1m'
        NC='\033[0m'
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        MAGENTA=''
        BOLD=''
        NC=''
    fi
}

USE_COLOR="auto"
setup_colours

# ============================================================================
# DEFAULT OPTIONS
# ============================================================================
DRY_RUN=false
VERBOSE=false
YES_MODE=false
BACKUP_TIMESTAMP=""

# Counters
CHANGES_MADE=0
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
    if [[ $# -lt 1 ]]; then
        show_help
        exit 1
    fi

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
            --list)
                list_backups
                exit 0
                ;;
            --no-color|--no-colour)
                USE_COLOR="never"
                setup_colours
                shift
                ;;
            --version|-V)
                echo "macOS Server Optimisation - Restore Utility v${VERSION}"
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                BACKUP_TIMESTAMP="$1"
                shift
                ;;
        esac
    done
}

show_help() {
    cat << EOF
macOS Server Optimisation - Restore Utility v${VERSION}

Usage: ./restore.sh <backup-timestamp> [OPTIONS]

Restores system settings from a backup created before optimisation.

ARGUMENTS:
  backup-timestamp       The timestamp of the backup to restore (e.g., 2025-12-31_143022)

OPTIONS:
  --dry-run              Preview restore without applying changes
  --verbose              Show detailed output
  --yes, -y              Skip confirmation prompts
  --list                 List available backups
  --no-color, --no-colour  Disable coloured output
  --version, -V          Show version number
  --help, -h             Show this help message

EXAMPLES:
  # List available backups
  ./restore.sh --list

  # Preview restore from a specific backup
  ./restore.sh 2025-12-31_143022 --dry-run

  # Restore from backup
  ./restore.sh 2025-12-31_143022

  # Restore with verbose output, no prompts
  ./restore.sh 2025-12-31_143022 --verbose --yes

ENVIRONMENT:
  NO_COLOR               Set to disable colours

EOF
}


list_backups() {
    print_header "Available Backups"

    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_error "Backup directory not found: ${BACKUP_DIR}"
        return 1
    fi

    local backups
    backups=$(ls -1 "${BACKUP_DIR}" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}$' || true)

    if [[ -z "${backups}" ]]; then
        log_warning "No backups found in ${BACKUP_DIR}"
        return 0
    fi

    echo "Timestamp              | Created               | System Info"
    echo "-----------------------|-----------------------|---------------------------"

    for backup in ${backups}; do
        local backup_path="${BACKUP_DIR}/${backup}"
        local manifest="${backup_path}/manifest.json"

        if [[ -f "${manifest}" ]]; then
            local date
            local hostname
            local macos_version

            date=$(grep '"date"' "${manifest}" | cut -d'"' -f4 || echo "Unknown")
            hostname=$(grep '"hostname"' "${manifest}" | cut -d'"' -f4 || echo "Unknown")
            macos_version=$(grep '"macos_version"' "${manifest}" | cut -d'"' -f4 || echo "Unknown")

            printf "%-22s | %-21s | %s (macOS %s)\n" "${backup}" "${date}" "${hostname}" "${macos_version}"
        else
            printf "%-22s | %-21s | %s\n" "${backup}" "Unknown" "Manifest missing"
        fi
    done

    echo ""
    echo "To restore: ./restore.sh <timestamp>"
}

# ============================================================================
# VALIDATE BACKUP
# ============================================================================
validate_backup() {
    local backup_path="$1"

    log_step "Validating backup integrity..."

    local required_files=(
        "manifest.json"
        "launchctl_disabled.csv"
        "sysctl_restore.conf"
        "pmset_restore.conf"
        "system_info.txt"
    )

    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "${backup_path}/${file}" ]]; then
            missing_files+=("${file}")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Backup is incomplete. Missing files:"
        for file in "${missing_files[@]}"; do
            echo "  - ${file}"
        done
        return 1
    fi

    log_success "Backup validation passed"
    return 0
}

# ============================================================================
# RESTORE LAUNCHCTL SERVICES
# ============================================================================
restore_launchctl() {
    local backup_path="$1"
    local disabled_file="${backup_path}/launchctl_disabled.csv"

    print_header "Restoring Service States"

    if [[ ! -f "${disabled_file}" ]]; then
        log_warning "No launchctl backup file found, skipping service restoration"
        return 0
    fi

    # First, re-enable all services that we may have disabled
    # Read the services.conf to know what we might have disabled
    local services_file="${SCRIPT_DIR}/config/services.conf"

    if [[ -f "${services_file}" ]]; then
        log_step "Re-enabling services from configuration..."

        local services_count=0
        while IFS='|' read -r domain service category description; do
            # Skip comments and empty lines
            [[ "${domain}" =~ ^#.*$ || -z "${domain}" ]] && continue

            domain=$(echo "${domain}" | xargs)
            service=$(echo "${service}" | xargs)

            local enable_cmd=""
            case "${domain}" in
                system)
                    enable_cmd="sudo launchctl enable system/${service}"
                    ;;
                user)
                    enable_cmd="launchctl enable user/${CURRENT_UID}/${service}"
                    ;;
                gui)
                    enable_cmd="launchctl enable gui/${CURRENT_UID}/${service}"
                    ;;
            esac

            if [[ -n "${enable_cmd}" ]]; then
                log_info "Re-enabling: ${service}"
                execute "${enable_cmd}" "Re-enabled ${service}" || true
                ((services_count++)) || true
            fi

        done < "${services_file}"
        log_verbose "Re-enabled ${services_count} services from configuration"
    else
        log_warning "Services configuration not found: ${services_file}"
        log_warning "Unable to re-enable services - only restoring from backup state"
    fi

    # Now restore the original disabled state from the backup
    log_step "Restoring original disabled states from backup..."

    while IFS='|' read -r domain service state; do
        # Skip comments and empty lines
        [[ "${domain}" =~ ^#.*$ || -z "${domain}" ]] && continue

        domain=$(echo "${domain}" | xargs)
        service=$(echo "${service}" | xargs)
        state=$(echo "${state}" | xargs)

        # If it was originally disabled, disable it again
        if [[ "${state}" == "true" ]]; then
            local disable_cmd=""
            case "${domain}" in
                system)
                    disable_cmd="sudo launchctl disable system/${service}"
                    ;;
                user)
                    disable_cmd="launchctl disable user/${CURRENT_UID}/${service}"
                    ;;
                gui)
                    disable_cmd="launchctl disable gui/${CURRENT_UID}/${service}"
                    ;;
            esac

            if [[ -n "${disable_cmd}" ]]; then
                log_info "Restoring disabled state: ${service}"
                execute "${disable_cmd}" "Disabled ${service}" || true
            fi
        fi

    done < "${disabled_file}"

    log_success "Service states restored"
}

# ============================================================================
# RESTORE SYSCTL SETTINGS
# ============================================================================
restore_sysctl() {
    local backup_path="$1"
    local sysctl_file="${backup_path}/sysctl_restore.conf"

    print_header "Restoring sysctl Settings"

    if [[ ! -f "${sysctl_file}" ]]; then
        log_warning "No sysctl backup file found, skipping"
        return 0
    fi

    while IFS='=' read -r param value; do
        # Skip comments and empty lines
        [[ "${param}" =~ ^#.*$ || -z "${param}" ]] && continue

        param=$(echo "${param}" | xargs)
        value=$(echo "${value}" | xargs)

        [[ -z "${param}" || -z "${value}" ]] && continue

        log_info "Restoring: ${param}=${value}"
        execute "sudo sysctl -w ${param}=${value}" "Restored ${param}" || true

    done < "${sysctl_file}"

    # Remove the persistent sysctl LaunchDaemon if it exists
    local sysctl_plist="/Library/LaunchDaemons/com.server.sysctl.plist"
    if [[ -f "${sysctl_plist}" ]]; then
        log_info "Removing persistent sysctl configuration..."
        execute "sudo launchctl unload ${sysctl_plist} 2>/dev/null || true" ""
        execute "sudo rm -f ${sysctl_plist}" "Removed sysctl LaunchDaemon"
    fi

    log_success "sysctl settings restored"
}

# ============================================================================
# RESTORE PMSET SETTINGS
# ============================================================================
restore_pmset() {
    local backup_path="$1"
    local pmset_file="${backup_path}/pmset_restore.conf"

    print_header "Restoring Power Management Settings"

    if [[ ! -f "${pmset_file}" ]]; then
        log_warning "No pmset backup file found, skipping"
        return 0
    fi

    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "${key}" =~ ^#.*$ || -z "${key}" ]] && continue

        key=$(echo "${key}" | xargs)
        value=$(echo "${value}" | xargs)

        [[ -z "${key}" || -z "${value}" ]] && continue

        log_info "Restoring: ${key}=${value}"
        execute "sudo pmset -a ${key} ${value}" "Restored ${key}" || true

    done < "${pmset_file}"

    log_success "Power management settings restored"
}

# ============================================================================
# RESTORE DEFAULTS (macOS Preferences)
# ============================================================================
restore_defaults() {
    local backup_path="$1"
    local plists_dir="${backup_path}/plists"

    print_header "Restoring macOS Preferences"

    if [[ ! -d "${plists_dir}" ]]; then
        log_warning "No defaults backup found, skipping"
        return 0
    fi

    for plist in "${plists_dir}"/*.plist; do
        if [[ -f "${plist}" ]]; then
            local domain
            domain=$(basename "${plist}" .plist)

            log_info "Restoring domain: ${domain}"
            execute "defaults import ${domain} '${plist}'" "Restored ${domain}" || true
        fi
    done

    # Restart affected processes
    if [[ "${DRY_RUN}" != "true" ]]; then
        log_step "Restarting affected processes..."
        killall Dock 2>/dev/null || true
        killall Finder 2>/dev/null || true
        killall SystemUIServer 2>/dev/null || true
    fi

    log_success "macOS preferences restored"
}

# ============================================================================
# RESTORE SPOTLIGHT
# ============================================================================
restore_spotlight() {
    print_header "Restoring Spotlight"

    log_info "Re-enabling Spotlight indexing..."
    execute "sudo mdutil -a -i on" "Re-enabled Spotlight indexing"

    log_success "Spotlight restored"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
main() {
    # Create log directory
    mkdir -p "${LOG_DIR}"

    # Initialise log file
    echo "# macOS Server Optimisation Restore Log" > "${LOG_FILE}"
    echo "# Started: $(date)" >> "${LOG_FILE}"
    echo "# Restoring from: ${BACKUP_TIMESTAMP}" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"

    # Show banner
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║            macOS Server Optimisation - Restore Utility                   ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo -e "${YELLOW}>>> DRY RUN MODE - No changes will be made <<<${NC}"
        echo ""
    fi

    # Validate backup timestamp
    local backup_path="${BACKUP_DIR}/${BACKUP_TIMESTAMP}"

    if [[ ! -d "${backup_path}" ]]; then
        log_error "Backup not found: ${backup_path}"
        echo ""
        echo "Available backups:"
        list_backups
        exit 1
    fi

    # Validate backup integrity
    if ! validate_backup "${backup_path}"; then
        log_error "Backup validation failed"
        exit 1
    fi

    # Show backup info
    print_header "Backup Information"
    cat "${backup_path}/system_info.txt" | head -20
    echo ""

    # Confirmation
    if [[ "${YES_MODE}" != "true" && "${DRY_RUN}" != "true" ]]; then
        echo -e "${YELLOW}WARNING: This will restore system settings to the state from ${BACKUP_TIMESTAMP}${NC}"
        echo ""
        local proceed
        proceed=$(ask_yes_no "Proceed with restoration?" "")
        if [[ "${proceed}" != "yes" ]]; then
            log_info "Restoration cancelled by user"
            exit 0
        fi
    fi

    # Perform restoration in reverse order
    restore_spotlight
    restore_defaults "${backup_path}"
    restore_pmset "${backup_path}"
    restore_sysctl "${backup_path}"
    restore_launchctl "${backup_path}"

    # Summary
    print_header "Restoration Complete"

    echo "Results:"
    echo -e "  ${GREEN}Changes applied:${NC} ${CHANGES_MADE}"
    echo -e "  ${RED}Errors:${NC} ${ERRORS_ENCOUNTERED}"
    echo ""

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo "Run without --dry-run to apply restoration."
    else
        echo "Log file: ${LOG_FILE}"
        echo ""
        echo -e "${BOLD}IMPORTANT:${NC} A restart is required for all changes to take effect."
        echo ""

        local restart_now
        restart_now=$(ask_yes_no "Restart now?" "no")
        if [[ "${restart_now}" == "yes" ]]; then
            log_info "Restarting system..."
            sudo shutdown -r now
        else
            echo ""
            echo "Remember to restart when convenient."
        fi
    fi
}

# ============================================================================
# ENTRY POINT
# ============================================================================
parse_arguments "$@"
main
