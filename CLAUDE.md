# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bash toolkit for optimising macOS Sequoia 15.7.3 as a high-performance server. Disables 53 consumer services, tunes network stack, and configures power management. All changes are reversible via backup/restore.

## Common Commands

```bash
# Preview all changes (dry run)
./optimise.sh --dry-run --verbose

# Run full optimisation
./optimise.sh --verbose

# Apply specific categories only
./optimise.sh --category=telemetry,network,power

# Create backup manually
./backup_settings.sh

# List available backups
./restore.sh --list

# Restore from backup
./restore.sh 2025-12-31_143022
```

## Architecture

### Script Flow
1. `optimise.sh` runs pre-flight checks (SIP status, admin privileges, disk space)
2. Calls `backup_settings.sh` to create timestamped backup
3. Prompts for conditional services (iCloud, Time Machine, Bluetooth)
4. Reads config files and applies changes via `launchctl`, `sysctl`, `pmset`, `defaults`
5. Logs all operations to `logs/optimisation_*.log`

### Configuration Files (config/)
- **services.conf**: Pipe-delimited format `DOMAIN|SERVICE_NAME|CATEGORY|DESCRIPTION`
  - Domains: `system` (requires sudo), `user`/`gui` (uses $UID)
  - Categories determine which services are applied together
- **sysctl.conf**: Network tuning parameters in `key=value` format
- **defaults.conf**: macOS preferences in `DOMAIN|KEY|TYPE|VALUE|DESCRIPTION` format

### Backup Structure (backups/TIMESTAMP/)
- `manifest.json`: Metadata for restoration
- `launchctl_disabled.csv`: Machine-readable service states
- `sysctl_restore.conf`, `pmset_restore.conf`: Values for rollback
- `plists/`: Exported defaults domains

### Critical Services (never modified)
mDNSResponder, configd, diskarbitrationd, securityd, trustd, opendirectoryd, launchd, WindowServer, cfprefsd, nsurlsessiond

## Code Patterns

- All scripts use `set -euo pipefail` for safety
- Colour-coded logging functions: `log_info`, `log_success`, `log_warning`, `log_error`
- `execute()` function handles dry-run mode and logging
- `is_category_selected()` checks if a category should be applied
- Service disabling uses `launchctl disable` (reversible) not plist deletion

## Requirements

- macOS 15.x (Sequoia)
- SIP disabled for persistent service changes
- Administrator access (sudo)
