#!/bin/bash
#
# macOS Server Optimisation - Backup Utility
# Creates a timestamped backup of current system settings before optimisation
#
# Usage: ./backup_settings.sh [OPTIONS]
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BACKUP_DIR="${SCRIPT_DIR}/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
VERSION="1.1.0"

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
        NC='\033[0m'
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        NC=''
    fi
}

USE_COLOR="auto"
setup_colours

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================
BACKUP_DIR="${DEFAULT_BACKUP_DIR}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --no-color|--no-colour)
            USE_COLOR="never"
            setup_colours
            shift
            ;;
        --version|-V)
            echo "macOS Server Optimisation - Backup Utility v${VERSION}"
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Creates a timestamped backup of current system settings."
            echo ""
            echo "Options:"
            echo "  --output-dir PATH    Directory to store backups (default: ./backups)"
            echo "  --no-color           Disable coloured output"
            echo "  --version, -V        Show version number"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Environment:"
            echo "  NO_COLOR             Set to disable colours"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create backup directory
BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"
mkdir -p "${BACKUP_PATH}"

log_info "Creating backup at: ${BACKUP_PATH}"
echo ""

# ============================================================================
# BACKUP SYSTEM INFORMATION
# ============================================================================
log_step "Backing up system information..."

{
    echo "# macOS Server Optimisation Backup"
    echo "# Timestamp: ${TIMESTAMP}"
    echo "# Date: $(date)"
    echo ""
    echo "## System Information"
    sw_vers
    echo ""
    echo "## Hardware"
    system_profiler SPHardwareDataType 2>/dev/null | grep -E "(Model|Processor|Memory|Cores)" || true
    echo ""
    echo "## SIP Status"
    csrutil status 2>/dev/null || echo "Unable to determine SIP status"
} > "${BACKUP_PATH}/system_info.txt"

log_success "System information saved"

# ============================================================================
# BACKUP LAUNCHCTL STATE
# ============================================================================
log_step "Backing up launchctl service states..."

# Get current UID
CURRENT_UID=$(id -u)

{
    echo "# launchctl disabled services state"
    echo "# Timestamp: ${TIMESTAMP}"
    echo ""
    echo "## System Domain Disabled Services"
    sudo launchctl print-disabled system 2>/dev/null || echo "Unable to get system disabled services"
    echo ""
    echo "## User Domain Disabled Services (UID: ${CURRENT_UID})"
    launchctl print-disabled user/${CURRENT_UID} 2>/dev/null || echo "Unable to get user disabled services"
    echo ""
    echo "## GUI Domain Disabled Services (UID: ${CURRENT_UID})"
    launchctl print-disabled gui/${CURRENT_UID} 2>/dev/null || echo "Unable to get GUI disabled services"
} > "${BACKUP_PATH}/launchctl_state.txt"

# Also create machine-readable format
{
    echo "# Machine-readable disabled services"
    echo "# Format: DOMAIN|SERVICE|DISABLED"
    echo ""

    # Parse system disabled (|| true prevents grep exit code 1 from failing script)
    sudo launchctl print-disabled system 2>/dev/null | grep -E "^\t" | while read -r line; do
        service=$(echo "$line" | awk -F'"' '{print $2}')
        state=$(echo "$line" | grep -o "=> true\|=> false" | awk '{print $2}')
        if [[ -n "$service" && -n "$state" ]]; then
            echo "system|${service}|${state}"
        fi
    done || true

    # Parse user disabled
    launchctl print-disabled user/${CURRENT_UID} 2>/dev/null | grep -E "^\t" | while read -r line; do
        service=$(echo "$line" | awk -F'"' '{print $2}')
        state=$(echo "$line" | grep -o "=> true\|=> false" | awk '{print $2}')
        if [[ -n "$service" && -n "$state" ]]; then
            echo "user|${service}|${state}"
        fi
    done || true

    # Parse GUI disabled
    launchctl print-disabled gui/${CURRENT_UID} 2>/dev/null | grep -E "^\t" | while read -r line; do
        service=$(echo "$line" | awk -F'"' '{print $2}')
        state=$(echo "$line" | grep -o "=> true\|=> false" | awk '{print $2}')
        if [[ -n "$service" && -n "$state" ]]; then
            echo "gui|${service}|${state}"
        fi
    done || true
} > "${BACKUP_PATH}/launchctl_disabled.csv"

log_success "launchctl state saved"

# ============================================================================
# BACKUP SYSCTL SETTINGS
# ============================================================================
log_step "Backing up sysctl settings..."

{
    echo "# sysctl values backup"
    echo "# Timestamp: ${TIMESTAMP}"
    echo ""

    # Network TCP settings
    echo "## Network TCP Settings"
    sysctl net.inet.tcp.sendspace 2>/dev/null || true
    sysctl net.inet.tcp.recvspace 2>/dev/null || true
    sysctl net.inet.tcp.autorcvbufmax 2>/dev/null || true
    sysctl net.inet.tcp.autosndbufmax 2>/dev/null || true
    sysctl net.inet.tcp.mssdflt 2>/dev/null || true
    sysctl net.inet.tcp.win_scale_factor 2>/dev/null || true
    sysctl net.inet.tcp.rfc1323 2>/dev/null || true
    sysctl net.inet.tcp.delayed_ack 2>/dev/null || true
    sysctl net.inet.tcp.sack 2>/dev/null || true
    sysctl net.inet.tcp.always_keepalive 2>/dev/null || true
    sysctl net.inet.tcp.slowstart_flightsize 2>/dev/null || true
    sysctl net.inet.tcp.local_slowstart_flightsize 2>/dev/null || true
    sysctl net.inet.tcp.msl 2>/dev/null || true
    sysctl net.inet.tcp.blackhole 2>/dev/null || true
    sysctl net.inet.udp.blackhole 2>/dev/null || true

    echo ""
    echo "## Kernel IPC Settings"
    sysctl kern.ipc.maxsockbuf 2>/dev/null || true
    sysctl kern.ipc.somaxconn 2>/dev/null || true

    echo ""
    echo "## Kernel Limits"
    sysctl kern.maxvnodes 2>/dev/null || true
    sysctl kern.maxproc 2>/dev/null || true
    sysctl kern.maxfiles 2>/dev/null || true
    sysctl kern.maxfilesperproc 2>/dev/null || true
    sysctl kern.maxprocperuid 2>/dev/null || true
} > "${BACKUP_PATH}/sysctl_backup.txt"

# Create restorable format
{
    echo "# Restorable sysctl values"
    sysctl net.inet.tcp.sendspace 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.recvspace 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.mssdflt 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.win_scale_factor 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.delayed_ack 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.slowstart_flightsize 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.local_slowstart_flightsize 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.msl 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.tcp.blackhole 2>/dev/null | tr -d ' ' || true
    sysctl net.inet.udp.blackhole 2>/dev/null | tr -d ' ' || true
    sysctl kern.ipc.maxsockbuf 2>/dev/null | tr -d ' ' || true
} > "${BACKUP_PATH}/sysctl_restore.conf"

log_success "sysctl settings saved"

# ============================================================================
# BACKUP PMSET SETTINGS
# ============================================================================
log_step "Backing up power management settings..."

{
    echo "# pmset settings backup"
    echo "# Timestamp: ${TIMESTAMP}"
    echo ""
    pmset -g 2>/dev/null || echo "Unable to get pmset settings"
    echo ""
    echo "## Full pmset output"
    pmset -g everything 2>/dev/null | head -100 || true
} > "${BACKUP_PATH}/pmset_backup.txt"

# Create restorable format
# Handle pmset values that may contain spaces or additional info (e.g., "1 (charged)")
{
    echo "# Restorable pmset values"
    pmset -g 2>/dev/null | grep -E "^\s+\w+" | while read -r line; do
        # Remove leading whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//')
        # Get the key (first word)
        key=$(echo "$line" | awk '{print $1}')
        # Get the value (second word only - ignore parenthetical info)
        # Values like "1 (charged)" should just use "1"
        value=$(echo "$line" | awk '{print $2}')
        # Skip if key or value is empty, or if it looks like a header
        if [[ -n "$key" && -n "$value" && ! "$key" =~ ^[A-Z] ]]; then
            # Only include numeric values or simple strings (not parenthetical)
            if [[ "$value" =~ ^[0-9]+$ || "$value" =~ ^[a-z]+$ ]]; then
                echo "${key}=${value}"
            fi
        fi
    done
} > "${BACKUP_PATH}/pmset_restore.conf"

log_success "Power management settings saved"

# ============================================================================
# BACKUP NVRAM SETTINGS
# ============================================================================
log_step "Backing up NVRAM settings..."

{
    echo "# NVRAM settings backup"
    echo "# Timestamp: ${TIMESTAMP}"
    echo ""
    sudo nvram -p 2>/dev/null || echo "Unable to get NVRAM settings"
} > "${BACKUP_PATH}/nvram_backup.txt"

# Extract boot-args specifically
BOOT_ARGS=$(sudo nvram boot-args 2>/dev/null | cut -f2 || echo "")
echo "boot-args=${BOOT_ARGS}" > "${BACKUP_PATH}/nvram_bootargs.txt"

log_success "NVRAM settings saved"

# ============================================================================
# BACKUP DEFAULTS (macOS Preferences)
# ============================================================================
log_step "Backing up macOS defaults..."

{
    echo "# macOS defaults backup"
    echo "# Timestamp: ${TIMESTAMP}"
    echo ""

    # Key domains we modify
    DOMAINS=(
        "com.apple.CrashReporter"
        "com.apple.SoftwareUpdate"
        "com.apple.commerce"
        "com.apple.SubmitDiagInfo"
        "com.apple.assistant.support"
        "com.apple.Siri"
        "com.apple.spotlight"
        "NSGlobalDomain"
        "com.apple.desktopservices"
        "com.apple.finder"
        "com.apple.dock"
        "com.apple.universalaccess"
        "com.apple.NetworkBrowser"
    )

    for domain in "${DOMAINS[@]}"; do
        echo "## Domain: ${domain}"
        defaults read "${domain}" 2>/dev/null || echo "Domain not found or empty"
        echo ""
    done
} > "${BACKUP_PATH}/defaults_backup.txt"

# Export specific domains as plists for easy restoration
mkdir -p "${BACKUP_PATH}/plists"
for domain in "com.apple.CrashReporter" "com.apple.SoftwareUpdate" "com.apple.commerce" "com.apple.Siri" "NSGlobalDomain" "com.apple.dock" "com.apple.finder"; do
    defaults export "${domain}" "${BACKUP_PATH}/plists/${domain}.plist" 2>/dev/null || true
done

log_success "macOS defaults saved"

# ============================================================================
# BACKUP SPOTLIGHT STATUS
# ============================================================================
log_step "Backing up Spotlight status..."

{
    echo "# Spotlight indexing status"
    echo "# Timestamp: ${TIMESTAMP}"
    echo ""
    sudo mdutil -s / 2>/dev/null || echo "Unable to get Spotlight status"
    echo ""
    sudo mdutil -as 2>/dev/null || echo "Unable to get all volumes status"
} > "${BACKUP_PATH}/spotlight_status.txt"

log_success "Spotlight status saved"

# ============================================================================
# CREATE MANIFEST
# ============================================================================
log_step "Creating backup manifest..."

{
    echo "{"
    echo "  \"timestamp\": \"${TIMESTAMP}\","
    echo "  \"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"macos_version\": \"$(sw_vers -productVersion)\","
    echo "  \"macos_build\": \"$(sw_vers -buildVersion)\","
    echo "  \"hostname\": \"$(hostname)\","
    echo "  \"username\": \"$(whoami)\","
    echo "  \"uid\": \"$(id -u)\","
    echo "  \"script_version\": \"${VERSION}\","
    echo "  \"files\": ["
    echo "    \"system_info.txt\","
    echo "    \"launchctl_state.txt\","
    echo "    \"launchctl_disabled.csv\","
    echo "    \"sysctl_backup.txt\","
    echo "    \"sysctl_restore.conf\","
    echo "    \"pmset_backup.txt\","
    echo "    \"pmset_restore.conf\","
    echo "    \"nvram_backup.txt\","
    echo "    \"nvram_bootargs.txt\","
    echo "    \"defaults_backup.txt\","
    echo "    \"spotlight_status.txt\","
    echo "    \"plists/\""
    echo "  ]"
    echo "}"
} > "${BACKUP_PATH}/manifest.json"

log_success "Manifest created"

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "============================================================================"
log_success "Backup completed successfully!"
echo "============================================================================"
echo ""
echo "Backup location: ${BACKUP_PATH}"
echo ""
echo "Contents:"
ls -la "${BACKUP_PATH}"
echo ""
echo "To restore from this backup, run:"
echo "  ./restore.sh ${TIMESTAMP}"
echo ""
