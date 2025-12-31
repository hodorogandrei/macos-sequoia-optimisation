# macOS Server Optimisation Toolkit

A comprehensive toolkit for transforming macOS Sequoia 15.7.3 into a high-performance server environment for resource-intensive web SaaS applications.

## Overview

This toolkit systematically disables consumer-oriented services, tunes the network stack, and configures power management for 24/7 server operation. All changes are reversible and extensively documented.

### Key Features

- **53 consumer services** identified for safe disabling
- **Network stack tuning** for high-throughput server workloads
- **Full backup and restore** capability
- **Dry-run mode** for previewing changes
- **Selective categories** for granular control
- **Interactive prompts** for conditional decisions
- **Colour-coded output** for easy status tracking (auto-detects terminal)
- **Comprehensive logging** for audit trails
- **CI/automation friendly** with `--no-color` and `NO_COLOR` support
- **Custom configuration** via `--config-dir` option
- **Lock file protection** against concurrent execution

## System Requirements

### Supported Configuration

| Requirement | This System | Notes |
|-------------|-------------|-------|
| macOS Version | 15.7.3 (Sequoia) | Script designed for macOS 15.x |
| Architecture | Intel (Mac mini 8,1) | Works on both Intel and Apple Silicon |
| RAM | 64GB | 16GB+ recommended for server workloads |
| SIP Status | Disabled | Required for persistent service changes |
| Server Mode | Enabled (`serverperfmode=1`) | Already configured |

### Prerequisites

1. **Administrator access** - Script requires sudo for system-level changes
2. **SIP disabled** - For persistent launchctl changes (already disabled on this system)
3. **Backup strategy** - Ensure important data is backed up before running

## Directory Structure

```
macos-optimisation-script/
├── backup_settings.sh      # Standalone backup utility
├── optimise.sh             # Main optimisation script
├── restore.sh              # Restoration from backup
├── README.md               # This documentation
├── config/
│   ├── services.conf       # Services to disable (editable)
│   ├── sysctl.conf         # Network tuning parameters
│   └── defaults.conf       # macOS preferences
├── docs/
│   ├── RESEARCH_FINDINGS.md    # Service research documentation
│   └── OPTIMISATION_PLAN.md    # Detailed optimisation plan
├── backups/                # Timestamped backup storage
│   └── YYYY-MM-DD_HHMMSS/
│       ├── launchctl_state.txt
│       ├── launchctl_disabled.csv
│       ├── sysctl_backup.txt
│       ├── pmset_backup.txt
│       ├── defaults_backup.txt
│       ├── nvram_backup.txt
│       ├── manifest.json
│       └── plists/
└── logs/
    └── optimisation_*.log
```

## Quick Start

### 1. Preview Changes (Recommended First Step)

```bash
./optimise.sh --dry-run --verbose
```

This shows all changes that would be made without actually applying them.

### 2. Run Full Optimisation

```bash
./optimise.sh --verbose
```

The script will:
1. Run pre-flight checks
2. Create a full backup
3. Prompt for conditional services (iCloud, Time Machine, Bluetooth)
4. Ask for confirmation
5. Apply optimisations
6. Show summary and offer to restart

### 3. Selective Optimisation

Apply only specific categories:

```bash
# Only disable telemetry and apply network tuning
./optimise.sh --category=telemetry,network

# Only disable consumer features (no prompts for conditional services)
./optimise.sh --category=consumer,media --yes
```

## Available Categories

| Category | Description | Risk Level |
|----------|-------------|------------|
| `telemetry` | Analytics, diagnostics, crash reporting | Very Low |
| `siri` | Siri, voice assistant, speech services | Very Low |
| `analysis` | Photo/media analysis, ML background tasks | Low |
| `consumer` | Game Center, Screen Time, Maps, Weather, etc. | Very Low |
| `media` | AirPlay, Music library, iTunes cloud | Very Low |
| `sharing` | AirDrop, Handoff, Sidecar | Low |
| `icloud` | iCloud sync services (interactive prompt) | Moderate |
| `backup` | Time Machine (interactive prompt) | Moderate |
| `bluetooth` | Bluetooth stack (interactive prompt) | Low |
| `network` | TCP/IP stack tuning | Low |
| `power` | Power management settings | Very Low |
| `defaults` | macOS preferences (updates, animations, etc.) | Very Low |
| `spotlight` | Spotlight indexing (interactive prompt) | Low |

## Command Reference

### backup_settings.sh

Creates a timestamped backup of current system settings.

```bash
# Create backup in default location (./backups/)
./backup_settings.sh

# Create backup in custom location
./backup_settings.sh --output-dir /path/to/backups
```

### optimise.sh

Main optimisation script with full feature set.

```bash
Usage: ./optimise.sh [OPTIONS]

Options:
  --dry-run              Preview changes without applying
  --verbose              Show detailed output
  --yes, -y              Skip confirmation prompts
  --skip-backup          Skip backup (not recommended)
  --category=LIST        Apply only specific categories
  --config-dir=PATH      Use custom configuration directory
  --no-color             Disable coloured output (auto-detected for pipes)
  --version, -V          Show version number
  --help, -h             Show help message

Environment:
  NO_COLOR               Set to disable colours (https://no-color.org/)

Examples:
  ./optimise.sh --dry-run              # Preview all changes
  ./optimise.sh --verbose              # Full optimisation with details
  ./optimise.sh --category=telemetry   # Only telemetry
  ./optimise.sh --yes --skip-backup    # Quick mode (for re-runs)
  ./optimise.sh --no-color | tee log   # CI-friendly with log capture
```

### restore.sh

Restores system to a previous state from backup.

```bash
Usage: ./restore.sh <backup-timestamp> [OPTIONS]

Options:
  --dry-run              Preview restoration
  --verbose              Show detailed output
  --yes, -y              Skip confirmation
  --list                 List available backups
  --no-color             Disable coloured output
  --version, -V          Show version number
  --help, -h             Show help message

Environment:
  NO_COLOR               Set to disable colours

Examples:
  ./restore.sh --list                          # List backups
  ./restore.sh 2025-12-31_143022               # Restore from backup
  ./restore.sh 2025-12-31_143022 --dry-run     # Preview restoration
```

## What Gets Optimised

### Services Disabled (53 total)

#### Telemetry & Analytics (9 services)
- `analyticsd` - Apple analytics daemon
- `awdd` - Apple wireless diagnostics
- `SubmitDiagInfo` - Diagnostic submission
- `CrashReporterSupportHelper` - Crash reporting
- `ecosystemanalyticsd` - Cross-device analytics
- `wifianalyticsd` - WiFi analytics
- `symptomsd-diag` - Network diagnostics
- `dprivacyd` - Differential privacy
- `appleseed.fbahelperd` - Feedback Assistant

#### Siri & Assistant (12 services)
All Siri-related services including `assistantd`, `parsecd`, `siriknowledged`, etc.

#### Photo/Media Analysis (10 services)
High CPU consumers: `photoanalysisd`, `mediaanalysisd`, `knowledgeconstructiond`, etc.

#### Consumer Features (22+ services)
`gamed`, `ScreenTimeAgent`, `tipsd`, `newsd`, `weatherd`, `Maps.*`, etc.

### Network Stack Tuning

| Parameter | Default | Optimised | Purpose |
|-----------|---------|-----------|---------|
| `net.inet.tcp.sendspace` | 131KB | 1MB | Larger send buffer |
| `net.inet.tcp.recvspace` | 131KB | 1MB | Larger receive buffer |
| `net.inet.tcp.autorcvbufmax` | 2MB | 32MB | Auto-tune ceiling |
| `net.inet.tcp.autosndbufmax` | 2MB | 32MB | Auto-tune ceiling |
| `net.inet.tcp.mssdflt` | 512 | 1460 | Modern MSS |
| `net.inet.tcp.win_scale_factor` | 3 | 8 | Higher window scaling |
| `net.inet.tcp.delayed_ack` | 3 | 0 | Lower latency |

### Power Management

- Power Nap: Disabled
- Proximity Wake: Disabled
- Sleep: Disabled (all types)
- Auto Restart: Enabled
- Wake on LAN: Enabled
- TCP Keepalive: Enabled

### macOS Preferences

- Crash dialogs: Disabled
- Auto updates: Disabled
- App Nap: Disabled
- Animations: Reduced
- .DS_Store on network: Disabled

## Services NEVER Modified

The following critical services are protected and never touched:

| Service | Reason |
|---------|--------|
| mDNSResponder | DNS resolution, Bonjour networking |
| configd | DHCP, network configuration |
| diskarbitrationd | Disk mounting/unmounting |
| securityd | Security framework |
| trustd | Certificate validation |
| opendirectoryd | Directory services |
| launchd | Init system |
| WindowServer | GUI rendering |
| cfprefsd | Preferences system |
| nsurlsessiond | URL handling (cannot be disabled) |

## Verifying Optimisations

After optimisation, verify with these commands:

```bash
# Check disabled services
launchctl print-disabled system | head -30
launchctl print-disabled gui/$(id -u) | head -50

# Verify network tuning
sysctl net.inet.tcp.sendspace
sysctl net.inet.tcp.recvspace
sysctl net.inet.tcp.mssdflt

# Check power settings
pmset -g

# Check Spotlight status
mdutil -s /

# View recent log
tail -50 logs/optimisation_*.log
```

## Troubleshooting

### Service Won't Disable

```
Bootstrap failed: 5: Input/output error
```

This usually means:
1. SIP is enabled - Boot to Recovery and run `csrutil disable`
2. Service is already disabled - Run `launchctl print-disabled system` to check

### Network Settings Don't Persist

Network settings are applied at boot via a LaunchDaemon. Check:

```bash
ls -la /Library/LaunchDaemons/com.server.sysctl.plist
sudo launchctl list | grep sysctl
```

### Restore Not Working

1. List available backups: `./restore.sh --list`
2. Check backup integrity: `cat backups/*/manifest.json`
3. Try dry-run first: `./restore.sh TIMESTAMP --dry-run`

### Something Broke After Optimisation

1. **Quick Recovery**: Restore from backup
   ```bash
   ./restore.sh --list
   ./restore.sh YYYY-MM-DD_HHMMSS
   ```

2. **Targeted Fix**: Re-enable specific service
   ```bash
   sudo launchctl enable system/com.apple.servicename
   sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.servicename.plist
   ```

3. **Full Reset**: Reset all services (requires restart)
   ```bash
   # This enables everything - use restore.sh instead if possible
   sudo launchctl print-disabled system | grep "=> true" | while read line; do
       service=$(echo "$line" | awk -F'"' '{print $2}')
       sudo launchctl enable "system/${service}"
   done
   ```

## Known Limitations

1. **SIP Requirement**: Full optimisation requires SIP disabled
2. **Restart Required**: Many changes only take effect after restart
3. **GUI Required**: WindowServer kept running for management access
4. **Some Services Respawn**: A few services are designed to restart automatically

## Changelog

### v1.1.0 (2025-12-31)
- Added `--no-color` / `--no-colour` option with automatic terminal detection
- Added `NO_COLOR` environment variable support (https://no-color.org/)
- Added `--config-dir=PATH` option for custom configuration directories
- Added `--version` / `-V` flag to all scripts
- Added lock file mechanism to prevent concurrent script execution
- Added category validation with warnings for unknown categories
- Added service existence verification before disable/enable attempts
- Fixed hardcoded sysctl LaunchDaemon - now dynamically generates from config
- Fixed defaults command quoting for domains with spaces
- Fixed pmset backup parsing for multi-word values
- Fixed inline comment handling in configuration files
- Improved restore.sh with warning when services.conf is missing

### v1.0.0 (2025-12-31)
- Initial release
- 53 services identified for safe disabling
- Full backup/restore capability
- Network stack tuning
- Power management configuration
- Interactive prompts for conditional services

## Research References

See `docs/RESEARCH_FINDINGS.md` for detailed research documentation including:
- Service-by-service analysis
- Source URLs for each recommendation
- Risk assessments
- Critical services documentation

## License

This toolkit is provided as-is for server optimisation purposes. Use at your own risk. Always maintain backups before modifying system settings.

---

**Generated for:** Mac mini 8,1 | Intel Core i7 | 64GB RAM | macOS 15.7.3 Sequoia
