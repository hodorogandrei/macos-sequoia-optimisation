# macOS Server Optimisation Toolkit

> [!CAUTION]
> ## ⚠️ IMPORTANT DISCLAIMER — READ CAREFULLY BEFORE USE
>
> ### Warranty Disclaimer
>
> **THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU.**
>
> No oral or written information or advice given by the authors shall create a warranty. The authors do not warrant that the software will meet your requirements, that operation will be uninterrupted or error-free, or that defects will be corrected.
>
> ### Limitation of Liability
>
> **IN NO EVENT SHALL THE AUTHORS, COPYRIGHT HOLDERS, OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, PUNITIVE, OR CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, BUT NOT LIMITED TO: LOSS OF DATA, LOSS OF PROFITS, LOSS OF BUSINESS, BUSINESS INTERRUPTION, LOSS OF GOODWILL, SYSTEM FAILURE, SECURITY BREACH, OR PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES) ARISING OUT OF OR IN CONNECTION WITH THE USE OR INABILITY TO USE THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.**
>
> Some jurisdictions do not allow the exclusion or limitation of incidental or consequential damages, so the above limitation may not apply to you. In such jurisdictions, the authors' liability shall be limited to the fullest extent permitted by applicable law.
>
> ### Assumption of Risk
>
> **By downloading, installing, or using this software, you expressly acknowledge and agree that:**
>
> 1. **You use this software entirely at your own risk**
> 2. You have been warned that this software modifies critical operating system components
> 3. You understand that disabling System Integrity Protection (SIP) creates serious security vulnerabilities ([Apple Developer Documentation](https://developer.apple.com/documentation/security/disabling-and-enabling-system-integrity-protection))
> 4. You accept sole responsibility for any damage, data loss, security breach, or system failure
> 5. You have made independent backups of all critical data before use
> 6. You have tested this software in a non-production environment
> 7. This software is intended for dedicated server environments, not personal workstations
> 8. Using this software may void Apple warranty or support eligibility
> 9. Future macOS updates may conflict with modifications made by this software
>
> ### Specific Risks
>
> This toolkit may cause:
> - **System instability** — Crashes, kernel panics, failure to boot
> - **Data loss** — From failed operations or dependent service failures
> - **Security vulnerabilities** — SIP disabled, services disabled, firewall modifications
> - **Application failures** — Apps depending on disabled services may malfunction
> - **Network issues** — TCP/IP modifications may cause connectivity problems
> - **Irreversible changes** — Some modifications may persist despite restore attempts
> - **Unauthorized access** — If security-related services are improperly disabled
>
> ### Indemnification
>
> You agree to indemnify, defend, and hold harmless the authors, contributors, and copyright holders from and against any and all claims, damages, losses, costs, and expenses (including reasonable legal fees) arising from your use of this software or violation of these terms.
>
> ### No Professional Advice
>
> This software and documentation do not constitute professional IT, security, or legal advice. If you require professional advice regarding system administration, security hardening, or legal matters, consult qualified professionals.
>
> ### Not Affiliated with Apple
>
> This software is **not endorsed, sponsored, or affiliated with Apple Inc.** in any way. macOS, Mac, Mac mini, and other Apple product names are trademarks of Apple Inc. Use of these names is for identification purposes only and does not imply endorsement.
>
> ### Acceptance
>
> **BY USING THIS SOFTWARE, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO BE BOUND BY THIS DISCLAIMER. IF YOU DO NOT AGREE, DO NOT USE THIS SOFTWARE.**

---

A comprehensive toolkit for transforming macOS Sequoia 15.7.3 into a high-performance server environment for resource-intensive web SaaS applications.

## Overview

This toolkit systematically disables consumer-oriented services, tunes the network stack, and configures power management for 24/7 server operation. All changes are reversible and extensively documented.

### Key Features

- **86 consumer services** identified for disabling (72 automatic + 14 conditional)
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
| Architecture | Intel (Mac mini 8,1) | **serverperfmode is Intel-only** per [Apple Support](https://support.apple.com/en-us/101992) |
| RAM | 64GB | 16GB+ recommended for server workloads |
| SIP Status | Disabled | Required for persistent `launchctl disable` changes |
| Server Mode | Enabled (`serverperfmode=1`) | Already configured |

> **Note:** Apple Silicon Macs do not support `serverperfmode`. The service disabling and network tuning portions of this toolkit still apply, but the kernel parameter optimisation via serverperfmode is Intel-specific.

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
  --accept-disclaimer    Accept legal disclaimer (REQUIRED for non-interactive use)
  --version, -V          Show version number
  --help, -h             Show help message

Environment:
  NO_COLOR               Set to disable colours (https://no-color.org/)

Examples:
  ./optimise.sh --dry-run              # Preview all changes (requires typing "I AGREE")
  ./optimise.sh --verbose              # Full optimisation with details
  ./optimise.sh --category=telemetry   # Only telemetry
  ./optimise.sh --yes --skip-backup    # Quick mode (for re-runs)
  ./optimise.sh --accept-disclaimer --yes | tee log   # CI/automation mode
```

> **Note:** Interactive use requires typing `I AGREE` to confirm acceptance of the legal disclaimer. For automation/CI pipelines, use `--accept-disclaimer` to confirm you have read and accept all terms in README.md and LICENSE.

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
  --accept-disclaimer    Accept legal disclaimer (REQUIRED for non-interactive use)
  --version, -V          Show version number
  --help, -h             Show help message

Environment:
  NO_COLOR               Set to disable colours

Examples:
  ./restore.sh --list                          # List backups
  ./restore.sh 2025-12-31_143022               # Restore from backup (requires "I AGREE")
  ./restore.sh 2025-12-31_143022 --dry-run     # Preview restoration
  ./restore.sh 2025-12-31_143022 --accept-disclaimer --yes  # Automation mode
```

## What Gets Optimised

### Services Disabled (86 total)

Services are organised into categories per `config/services.conf`:
- **Automatic (72):** telemetry (9), siri (12), analysis (10), consumer (24), media (11), sharing (6)
- **Conditional (14):** icloud (9), backup (2), bluetooth (3) — prompted interactively

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

Based on [ESnet Host Tuning](https://fasterdata.es.net/host-tuning/osx/) and [Rolande's macOS Sequoia 15.6 tuning](https://rolande.wordpress.com/2025/08/07/performance-tuning-the-network-stack-on-macos-sequoia-15-6/):

| Parameter | Default | Optimised | Purpose |
|-----------|---------|-----------|---------|
| `net.inet.tcp.sendspace` | 131,702 | 1,048,576 | Larger send buffer (1MB) |
| `net.inet.tcp.recvspace` | 131,702 | 1,048,576 | Larger receive buffer (1MB) |
| `net.inet.tcp.autorcvbufmax` | 4,194,304 | 33,554,432 | Auto-tune ceiling (32MB) |
| `net.inet.tcp.autosndbufmax` | 4,194,304 | 33,554,432 | Auto-tune ceiling (32MB) |
| `net.inet.tcp.mssdflt` | 512 | 1460 | Modern Ethernet MSS (1500 - 40 byte headers) |
| `net.inet.tcp.win_scale_factor` | 3 | 8 | [RFC 7323](https://www.rfc-editor.org/rfc/rfc7323) window scaling (256× multiplier) |
| `net.inet.tcp.delayed_ack` | 3 | 0 | Disable delayed ACKs for lower latency |

> **Note:** `net.inet.tcp.rfc1323` was removed in El Capitan 10.11 ([Apple Community](https://discussions.apple.com/thread/7408993)). RFC 1323 timestamps and window scaling are now enabled by default and not user-configurable.

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

| Service | Reason | Source |
|---------|--------|--------|
| mDNSResponder | DNS resolution, Bonjour networking. Apple replaced it with `discoveryd` in Yosemite; reverting in 10.10.4 closed ~300 bugs | [9to5Mac](https://9to5mac.com/2015/05/26/apple-drops-discoveryd-in-latest-os-x-beta-following-months-of-complaints-about-network-issues-with-yosemite/), [HowToGeek](https://www.howtogeek.com/338914/what-is-mdnsresponder-and-why-is-it-running-on-my-mac/) |
| configd | DHCP, network configuration | [Apple Support](https://support.apple.com/en-gb/102685) |
| diskarbitrationd | Disk mounting/unmounting | System critical |
| securityd | Security framework, keychain access | System critical |
| trustd | Certificate validation | System critical |
| opendirectoryd | Directory services, user authentication | System critical |
| launchd | Init system - parent of all processes | System critical |
| WindowServer | GUI rendering (needed for management) | System critical |
| cfprefsd | Preferences system | System critical |
| nsurlsessiond | URL handling - respawns if killed | [MacPaw](https://macpaw.com/how-to/remove-nsurlsessiond-from-mac) |

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

### Platform Restrictions

| Limitation | Details | Source |
|------------|---------|--------|
| **Intel Macs Only** | `serverperfmode=1` is only supported on Intel-based Macs | [Apple Support HT202528](https://support.apple.com/en-us/101992) |
| **macOS Sequoia** | Tested on 15.7.3; other versions may have different sysctl parameters or service names | Verified on target system |
| **Apple Silicon** | Apple Silicon Macs cannot use serverperfmode; service disabling still works but Apple Intelligence features require M1+ | [Apple Support](https://support.apple.com/en-us/120282) |
| **Intel macOS Future** | macOS Tahoe 26 (Fall 2025) will be the last version supporting Intel Macs | [Wikipedia](https://en.wikipedia.org/wiki/MacOS_Sequoia) |

### SIP (System Integrity Protection) Requirements

Per [Apple Developer Documentation](https://developer.apple.com/documentation/security/disabling-and-enabling-system-integrity-protection):

| Operation | SIP Required? | Notes |
|-----------|---------------|-------|
| `launchctl disable system/*` | **Yes** | Persistent service disabling requires SIP disabled |
| `launchctl disable gui/*` | **Yes** | GUI-level service disabling requires SIP disabled |
| `sysctl -w` (temporary) | No | Runtime changes work with SIP enabled |
| Persistent sysctl via LaunchDaemon | **Yes** | Writing to `/Library/LaunchDaemons/` may require SIP disabled |
| `pmset` changes | No | Power management works with SIP enabled |
| `defaults write` | Varies | System domains may require SIP disabled |

> **Security Warning:** Disabling SIP removes a critical security layer. Apple states: "Disable system protections only temporarily during development." With SIP disabled, malicious software could modify protected system files. Consider re-enabling SIP after applying changes, though this will prevent the changes from persisting across reboots.

### Technical Limitations

1. **Restart Required**: Service disable/enable changes require logout or restart to take full effect
2. **GUI Required**: WindowServer must remain running for remote management access (Screen Sharing, ARD)
3. **Some Services Respawn**: Certain services like `nsurlsessiond` are designed to restart automatically ([MacPaw](https://macpaw.com/how-to/remove-nsurlsessiond-from-mac))
4. **Service Dependencies**: Disabling one service may affect others; e.g., disabling `mDNSResponder` breaks all networking ([HowToGeek](https://www.howtogeek.com/338914/what-is-mdnsresponder-and-why-is-it-running-on-my-mac/))
5. **NVRAM Reset**: If NVRAM is reset, `serverperfmode` setting is cleared and must be re-applied

## Known Issues

| Issue | Description | Workaround |
|-------|-------------|------------|
| Service count discrepancy | Initial commit stated "53 services" but actual count is 86 | Documentation corrected in v1.1.0 |
| TCP buffer defaults | Earlier documentation cited incorrect default values | Corrected to verified Sequoia 15.6 values |
| Some services may not exist | Not all listed services exist on all macOS installations | Script checks existence before attempting disable |

## Acknowledgements & Documentation Gaps

### Verified Against Authoritative Sources

| Topic | Verification Status | Primary Source |
|-------|---------------------|----------------|
| serverperfmode | ✅ Verified | [Apple Support HT202528](https://support.apple.com/en-us/101992) |
| launchctl domains | ✅ Verified | `man launchctl`, [SS64](https://ss64.com/mac/launchctl.html) |
| SIP requirements | ✅ Verified | [Apple Developer Docs](https://developer.apple.com/documentation/security/disabling-and-enabling-system-integrity-protection) |
| TCP sysctl defaults | ✅ Verified | [Rolande's Sequoia 15.6 analysis](https://rolande.wordpress.com/2025/08/07/performance-tuning-the-network-stack-on-macos-sequoia-15-6/) |
| RFC 1323 removal | ✅ Verified | [Apple Community](https://discussions.apple.com/thread/7408993), removed in El Capitan 10.11 |
| mDNSResponder/discoveryd | ✅ Verified | [9to5Mac](https://9to5mac.com/2015/05/26/apple-drops-discoveryd-in-latest-os-x-beta-following-months-of-complaints-about-network-issues-with-yosemite/), [MacRumors](https://www.macrumors.com/2015/05/26/apple-discoveryd-replaced-with-mdnsresponder/) |
| SUDO_UID behaviour | ✅ Verified | [sudo.ws manual](https://www.sudo.ws/docs/man/1.8.31/sudoers.man/) |
| pmset parameters | ✅ Verified | `man pmset`, [SS64](https://ss64.com/mac/pmset.html) |
| NO_COLOR standard | ✅ Verified | [no-color.org](https://no-color.org/) |
| TCP blackhole settings | ✅ Verified | [FreeBSD man blackhole](https://man.freebsd.org/cgi/man.cgi?query=blackhole), [Apple Support Stealth Mode](https://support.apple.com/en-lb/guide/mac-help/mh17133/mac) |

### Unverified / Best-Effort Documentation

The following items lack official Apple documentation and are based on community research, XNU kernel source analysis, or empirical testing:

| Topic | Status | Notes |
|-------|--------|-------|
| `net.inet.tcp.delayed_ack` values | ⚠️ Partial | Values 0-3 derived from XNU source and community testing; Apple does not document these |
| Individual service safety | ⚠️ Community-sourced | Many services cited as "safe to disable" based on community experience, not Apple guidance |
| sysctl parameter documentation | ⚠️ Source code only | Apple provides no official documentation; [XNU kernel source](https://github.com/apple/darwin-xnu) is authoritative |
| Service interdependencies | ⚠️ Empirical | No comprehensive dependency map exists; based on testing and community reports |
| Optimal TCP buffer sizes | ⚠️ Workload-dependent | Values from [ESnet](https://fasterdata.es.net/host-tuning/osx/) are recommendations, not guarantees |

### `net.inet.tcp.delayed_ack` Values (XNU Source Analysis)

Based on analysis of [XNU kernel source](https://github.com/apple/darwin-xnu/blob/main/bsd/netinet/tcp_input.c):

| Value | Behaviour | Use Case |
|-------|-----------|----------|
| 0 | Disabled — ACKs sent immediately | Low-latency server workloads |
| 1 | Basic delayed ACK | General use |
| 2 | More restrictive — honours PUSH flag | Compatibility mode |
| 3 | Auto-detect / "Stretch ACKs" (default) | macOS default; adapts based on connection characteristics |

## Transparency Statement

This toolkit was developed for a specific use case (high-performance web SaaS server on Mac mini 8,1) and may not be suitable for all environments. The authors have made best efforts to:

1. **Cite authoritative sources** wherever possible (Apple documentation, RFCs, man pages)
2. **Acknowledge limitations** in documentation and testing
3. **Prefer conservative defaults** — services are disabled, not deleted
4. **Provide full reversibility** via backup/restore functionality
5. **Test on real hardware** — all changes verified on the target system

**What this toolkit is NOT:**
- Not Apple-endorsed or officially supported
- Not a replacement for proper security hardening
- Not guaranteed to improve performance in all scenarios
- Not suitable for multi-user workstations or laptops
- Not tested on Apple Silicon Macs (community contributions welcome)

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

## Authoritative References

### Official Apple Documentation
- [Turn on performance mode for macOS Server](https://support.apple.com/en-us/101992) - serverperfmode (Intel-only)
- [Edit property lists in Terminal](https://support.apple.com/guide/terminal/edit-property-lists-apda49a1bb2-577e-4721-8f25-ffc0836f6997/mac) - defaults command
- [configd man page](https://support.apple.com/en-gb/102685) - Network configuration daemon

### Man Pages & System Documentation
- `man launchctl` - Service management ([SS64 reference](https://ss64.com/mac/launchctl.html))
- `man pmset` - Power management ([SS64 reference](https://ss64.com/mac/pmset.html))
- `man sysctl` - Kernel parameters ([Apple Developer Archive](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/sysctl.3.html))

### Network Tuning Sources
- [ESnet Host Tuning - macOS](https://fasterdata.es.net/host-tuning/osx/) - High-performance networking
- [Rolande's macOS Sequoia 15.6 Tuning](https://rolande.wordpress.com/2025/08/07/performance-tuning-the-network-stack-on-macos-sequoia-15-6/) - Current sysctl defaults
- [RFC 7323](https://www.rfc-editor.org/rfc/rfc7323) - TCP Extensions for High Performance (supersedes RFC 1323)

### Technical Standards
- [NO_COLOR](https://no-color.org/) - Colour output disable standard
- [sudo.ws Manual](https://www.sudo.ws/docs/man/1.8.31/sudoers.man/) - SUDO_UID documentation
- [launchd.info](https://www.launchd.info/) - launchd tutorial and reference

### Additional Research
See `docs/RESEARCH_FINDINGS.md` for service-by-service analysis with source citations.

## Contributing

Contributions are welcome, particularly:
- Testing on Apple Silicon Macs
- Verification of service safety on different macOS versions
- Bug reports with detailed reproduction steps
- Documentation improvements with authoritative sources

Please open an issue before submitting pull requests for significant changes.

## License

This project is provided under the **MIT License**. See the [LICENSE](LICENSE) file for the complete license text and additional disclaimers.

**Summary:** You may use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software, provided you include the copyright notice and the "AS IS" warranty disclaimer. The software is provided without warranty, and the authors are not liable for any damages.

## Legal Notice

The disclaimers and limitations of liability contained in this document and the LICENSE file are provided for informational purposes and do not constitute legal advice. The enforceability of disclaimers varies by jurisdiction. If you have concerns about liability or legal compliance, consult with a qualified legal professional in your jurisdiction before using this software.

---

**Developed for:** Mac mini 8,1 | Intel Core i7 6-core @ 3.2GHz | 64GB RAM | macOS 15.7.3 Sequoia

**Last updated:** 2025-12-31 | **Version:** 1.1.0
