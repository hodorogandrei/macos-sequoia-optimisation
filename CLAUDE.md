# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bash toolkit (v1.1.0) for optimising macOS Sequoia 15.7.3 as a high-performance server. Disables 86 consumer services (72 automatic + 14 conditional), tunes network stack, and configures power management. All changes are reversible via backup/restore.

**Target Hardware:** Intel-based Macs only (serverperfmode is Intel-specific per [Apple Support](https://support.apple.com/en-us/101992)).

## Common commands

```bash
# Preview all changes (dry run)
./optimise.sh --dry-run --verbose

# Run full optimisation
./optimise.sh --verbose

# Apply specific categories only
./optimise.sh --category=telemetry,network,power

# Use custom config directory
./optimise.sh --config-dir=/etc/server-opt

# CI-friendly mode (no colours, piped output)
NO_COLOR=1 ./optimise.sh --yes | tee optimise.log

# Create backup manually
./backup_settings.sh

# List available backups
./restore.sh --list

# Restore from backup
./restore.sh 2025-12-31_143022

# Check version
./optimise.sh --version
```

## Architecture

### Script flow
1. `optimise.sh` runs pre-flight checks (SIP status, admin privileges, disk space)
2. Calls `backup_settings.sh` to create timestamped backup
3. Prompts for conditional services (iCloud, Time Machine, Bluetooth)
4. Reads config files and applies changes via `launchctl`, `sysctl`, `pmset`, `defaults`
5. Logs all operations to `logs/optimisation_*.log`

### Configuration files (config/)
- **services.conf**: Pipe-delimited format `DOMAIN|SERVICE_NAME|CATEGORY|DESCRIPTION`
  - Domains: `system` (requires sudo), `user`/`gui` (uses $UID)
  - Categories determine which services are applied together
- **sysctl.conf**: Network tuning parameters in `key=value` format
- **defaults.conf**: macOS preferences in `DOMAIN|KEY|TYPE|VALUE|DESCRIPTION` format

### Backup structure (backups/TIMESTAMP/)
- `manifest.json`: Metadata for restoration
- `launchctl_disabled.csv`: Machine-readable service states
- `sysctl_restore.conf`, `pmset_restore.conf`: Values for rollback
- `plists/`: Exported defaults domains

### Critical services (never modified)
mDNSResponder, configd, diskarbitrationd, securityd, trustd, opendirectoryd, launchd, WindowServer, cfprefsd, nsurlsessiond

## Code patterns

- All scripts use `set -euo pipefail` for safety
- Colour-coded logging functions: `log_info`, `log_success`, `log_warning`, `log_error`
- `setup_colours()` handles terminal detection and NO_COLOR support
- `execute()` function handles dry-run mode and logging
- `is_category_selected()` checks if a category should be applied
- `validate_categories()` validates category names before processing
- `service_exists()` checks if service exists before disable/enable
- `strip_inline_comment()` handles inline comments in config values
- `acquire_lock()` / `release_lock()` prevent concurrent execution
- Service disabling uses `launchctl disable` (reversible) not plist deletion
- sysctl LaunchDaemon is dynamically generated from config/sysctl.conf

## New options (v1.1.0)

| Option | Scripts | Description |
|--------|---------|-------------|
| `--no-color` | all | Disable coloured output |
| `--version` | all | Show version number |
| `--config-dir=PATH` | optimise.sh | Custom config directory |
| `NO_COLOR` env | all | Standard colour disable |

## Requirements

- macOS 15.x (Sequoia)
- **Intel-based Mac** - serverperfmode is Intel-only ([Apple Support HT202528](https://support.apple.com/en-us/101992))
- SIP disabled for persistent service changes via `launchctl disable` ([launchd.info](https://www.launchd.info/))
- Administrator access (sudo)

## Technical references

### launchctl domains
Per [SS64 launchctl documentation](https://ss64.com/mac/launchctl.html) and the `man launchctl` page:
- `system/[service]` - System-wide daemons from `/System/Library/LaunchDaemons` and `/Library/LaunchDaemons`. Requires root.
- `user/<uid>/[service]` - User-level agents. Exists for SSH sessions and background services.
- `gui/<uid>/[service]` - GUI-level agents for graphical login sessions. Shares namespace with user domain but discrete service sets.

### sysctl TCP parameters
Default values verified on macOS Sequoia 15.6 ([Rolande's Ramblings](https://rolande.wordpress.com/2025/08/07/performance-tuning-the-network-stack-on-macos-sequoia-15-6/)):

| Parameter | Default | Configured | Notes |
|-----------|---------|------------|-------|
| `net.inet.tcp.mssdflt` | 512 | 1460 | Modern Ethernet MSS; with RFC 1323 timestamps (12 bytes overhead), effective MSS is 1448 |
| `net.inet.tcp.sendspace` | 131,702 | 1,048,576 | Default socket send buffer |
| `net.inet.tcp.recvspace` | 131,702 | 1,048,576 | Default socket receive buffer |
| `net.inet.tcp.autorcvbufmax` | 4,194,304 | 33,554,432 | Max auto-tuned receive buffer |
| `net.inet.tcp.autosndbufmax` | 4,194,304 | 33,554,432 | Max auto-tuned send buffer |
| `net.inet.tcp.win_scale_factor` | 3 | 8 | Window scale per [RFC 7323](https://www.rfc-editor.org/rfc/rfc7323); value 8 = 256× multiplier |
| `net.inet.tcp.delayed_ack` | 3 | 0 | 0=disabled, 3=auto-detect |

Source: [ESnet Host Tuning](https://fasterdata.es.net/host-tuning/osx/) for high-performance networking recommendations.

### RFC 1323 (TCP extensions)
- **Removed from sysctl** in El Capitan 10.11 ([Apple Community thread](https://discussions.apple.com/thread/7408993))
- Window scaling and timestamps are **enabled by default** and not user-configurable in modern macOS
- The XNU kernel source is the authoritative reference for TCP stack behaviour

### serverperfmode
Per [Apple Support HT202528](https://support.apple.com/en-us/101992):
- Only applies to **Intel-based Macs**
- Adjusts kernel limits: `kern.maxproc`, `kern.maxfiles`, `kern.maxfilesperproc`, `kern.maxprocperuid`, `kern.ipc.somaxconn`
- Requires NVRAM setting and reboot
- Clears if NVRAM is reset

### pmset power management
Per `man pmset` and [SS64 pmset reference](https://ss64.com/mac/pmset.html):
- `powernap` - Power Nap feature for background updates during sleep
- `proximitywake` - Wake when paired iCloud devices approach ([Eclectic Light](https://eclecticlight.co/2017/01/20/power-management-in-detail-using-pmset/))
- Settings stored in `/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist`

### Critical services - why protected
| Service | Reason | Source |
|---------|--------|--------|
| mDNSResponder | Core DNS/Bonjour. Apple replaced it with `discoveryd` in Yosemite; restoring it in 10.10.4 closed ~300 bugs | [9to5Mac](https://9to5mac.com/2015/05/26/apple-drops-discoveryd-in-latest-os-x-beta-following-months-of-complaints-about-network-issues-with-yosemite/), [HowToGeek](https://www.howtogeek.com/338914/what-is-mdnsresponder-and-why-is-it-running-on-my-mac/) |
| configd | DHCP, network configuration | [Apple Support](https://support.apple.com/en-gb/102685) |
| nsurlsessiond | Cannot be permanently disabled; respawns | [MacPaw](https://macpaw.com/how-to/remove-nsurlsessiond-from-mac) |

### SUDO_UID environment variable
Per [sudo.ws manual](https://www.sudo.ws/docs/man/1.8.31/sudoers.man/):
- Set automatically by sudo to the UID of the invoking user
- Essential for targeting correct `gui/$UID` and `user/$UID` domains when script runs under sudo

### Bash strict mode
`set -euo pipefail` is the "unofficial bash strict mode" ([redsymbol.net](http://redsymbol.net/articles/unofficial-bash-strict-mode/)):
- `-e` (errexit): Exit immediately on non-zero exit status
- `-u` (nounset): Treat unset variables as errors
- `-o pipefail`: Pipeline fails if any command fails, not just the last

### NO_COLOR standard
Per [no-color.org](https://no-color.org/):
- Informal standard proposed 2017
- When set (to any value), disables ANSI colour output
- Complements terminal detection via `[ -t 1 ]`

### TCP delayed_ack values
Based on [XNU kernel source](https://github.com/apple/darwin-xnu/blob/main/bsd/netinet/tcp_input.c) analysis:
- `0` = Disabled (ACKs sent immediately) — recommended for low-latency servers
- `1` = Basic delayed ACK
- `2` = More restrictive, honours PUSH flag
- `3` = Auto-detect / "Stretch ACKs" (macOS default)

## Documentation gaps

The following lack official Apple documentation:
- **sysctl TCP parameters**: Only documented in [XNU source](https://github.com/apple/darwin-xnu)
- **Individual service safety**: Based on community testing, not Apple guidance
- **Service interdependencies**: No official dependency map exists
- **Optimal buffer sizes**: Workload-dependent; ESnet values are recommendations

## Ethical and safety guidelines

When modifying this codebase:
1. **Never remove safety checks** (SIP status, admin privileges, disk space)
2. **Always preserve backup functionality** — users must be able to revert
3. **Test changes on non-production systems** before merging
4. **Cite authoritative sources** when adding new claims
5. **Mark unverified claims** with ⚠️ in documentation
6. **Do not add services to disable** without research and justification
7. **Maintain the critical services blocklist** — never modify protected services
