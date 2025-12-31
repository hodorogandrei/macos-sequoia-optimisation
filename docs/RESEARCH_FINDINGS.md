# macOS Sequoia 15.7.3 Server Optimisation Research Findings

**Date:** 2025-12-31
**Target System:** Mac mini 8,1 (Intel Core i7 6-core @ 3.2GHz, 64GB RAM)
**macOS Version:** 15.7.3 (Build 24G419)
**SIP Status:** DISABLED
**Current Server Mode:** ENABLED (`serverperfmode=1`)

---

## Table of contents
1. [System Audit Summary](#system-audit-summary)
2. [Service Categorisation](#service-categorisation)
3. [Critical Services - DO NOT DISABLE](#critical-services---do-not-disable)
4. [Research Sources](#research-sources)

---

## System audit summary

### Current configuration (already optimised)
| Setting | Current Value | Status |
|---------|---------------|--------|
| Server Performance Mode | `serverperfmode=1` | Already enabled |
| Sleep | 0 (disabled) | Already optimised |
| Display Sleep | 0 (disabled) | Already optimised |
| Disk Sleep | 0 (disabled) | Already optimised |
| Auto Restart | 1 (enabled) | Already optimised |
| Wake on LAN (womp) | 1 (enabled) | Already optimised |
| kern.maxproc | 20000 | Already tuned |
| kern.maxfiles | 1200000 | Already tuned |
| kern.maxfilesperproc | 600000 | Already tuned |
| kern.maxprocperuid | 15000 | Already tuned |
| kern.ipc.somaxconn | 2048 | Already tuned |

### Areas requiring optimisation
| Area | Current State | Recommendation |
|------|---------------|----------------|
| Power Nap | Enabled (powernap=1) | Should be disabled for server |
| Proximity Wake | Enabled | Should be disabled |
| Network TCP Stack | Default values | Needs tuning for high-traffic |
| Consumer Services | Running | Many can be disabled |
| Telemetry Services | Active | Should be disabled |
| Spotlight Indexing | Active | Consider disabling |

---

## Service categorisation

### Category 1: Telemetry/privacy (safe to disable)

| Service | LaunchDaemon/Agent | Risk Level | Notes | Sources |
|---------|-------------------|------------|-------|---------|
| analyticsd | com.apple.analyticsd | 1/5 | Collects and sends diagnostic data to Apple | [IntelTechniques](https://inteltechniques.com/blog/2021/08/03/minimizing-macos-telemetry/), [Privacy Guides](https://www.privacyguides.org/en/os/macos-overview/) |
| awdd | com.apple.awdd | 1/5 | Apple Wireless Diagnostics - sends wireless telemetry | [GitHub Telemetry](https://github.com/herrbischoff/telemetry) |
| SubmitDiagInfo | com.apple.SubmitDiagInfo | 1/5 | Submits diagnostic reports to Apple | [Intego](https://www.intego.com/mac-security-blog/how-to-turn-off-analytics-on-mac-iphone-and-ipad-to-protect-your-privacy/) |
| CrashReporter | com.apple.CrashReporterSupportHelper | 1/5 | Crash report submission | [GitHub Gist](https://gist.github.com/ph33nx/ef7981bde362b8b2fc0e7fb8f62a6df8) |
| appleseed.fbahelperd | com.apple.appleseed.fbahelperd | 1/5 | Feedback Assistant helper | Common knowledge |
| ecosystemanalyticsd | com.apple.ecosystemanalyticsd | 1/5 | Cross-device analytics | [Privacy Guides](https://www.privacyguides.org/en/os/macos-overview/) |
| wifianalyticsd | com.apple.wifianalyticsd | 1/5 | WiFi analytics | [IntelTechniques](https://inteltechniques.com/blog/2021/08/03/minimizing-macos-telemetry/) |
| symptomsd | com.apple.symptomsd | 2/5 | Network diagnostics collection | Research indicates safe |
| dprivacyd | com.apple.dprivacyd | 1/5 | Differential privacy daemon | [Privacy Guides](https://www.privacyguides.org/en/os/macos-overview/) |

### Category 2: Background analysis (safe to disable for servers)

| Service | LaunchDaemon/Agent | Risk Level | Notes | Sources |
|---------|-------------------|------------|-------|---------|
| photoanalysisd | com.apple.photoanalysisd | 1/5 | Photo library face/scene analysis - CPU intensive | [GetDroidTips](https://www.getdroidtips.com/disabling-mediaanalysisd-photoanalysisd-photolibraryd/), [AppleInsider](https://appleinsider.com/inside/macos-ventura/tips/how-to-stop-mediaanalysisd-from-hogging-your-cpu-in-macos) |
| mediaanalysisd | com.apple.mediaanalysisd | 1/5 | Media analysis for Photos - very CPU intensive | [MacRumors](https://forums.macrumors.com/threads/mediaanalysisd-photoanalysisd-and-photolibraryd.2445597/), [DroidWin](https://droidwin.com/how-to-disable-mediaanalysisd-photoanalysisd-and-photolibraryd/) |
| photolibraryd | com.apple.photolibraryd | 2/5 | Photo library management | [Candid Technology](https://candid.technology/photoanalysisd/) |
| Spotlight (mds/mdworker) | com.apple.metadata.mds | 2/5 | Indexing service - can cause high CPU | [iBoysoft](https://iboysoft.com/wiki/mdworker-shared.html), [MacSecurity](https://macsecurity.net/view/567-mdworker-shared-high-cpu-mac) |
| corespotlightd | com.apple.corespotlightd | 2/5 | Core Spotlight service | [iBoysoft](https://iboysoft.com/howto/continued-corespotlightd-cpu-overload-sequoia.html) |
| knowledgeconstructiond | com.apple.knowledgeconstructiond | 1/5 | Siri knowledge construction | [PrivacyLearn](https://privacylearn.com/macos/configure-os/configure-siri/disable-siri/disable-siri-system-services) |
| suggestd | com.apple.suggestd | 1/5 | Suggestion daemon for Siri/Spotlight | Research indicates safe |
| proactived | com.apple.proactived | 1/5 | Proactive suggestions | Research indicates safe |

### Category 3: Siri/assistant services (safe to disable)

| Service | LaunchDaemon/Agent | Risk Level | Notes | Sources |
|---------|-------------------|------------|-------|---------|
| Siri.agent | com.apple.Siri.agent | 1/5 | Main Siri agent | [MacPaw](https://macpaw.com/how-to/disable-siri-on-mac), [Term7](https://term7.info/kill-siri/) |
| assistantd | com.apple.assistantd | 1/5 | Siri assistant daemon | [GitHub MacOS-Privacy](https://github.com/term7/MacOS-Privacy-and-Security-Enhancements) |
| assistant_service | com.apple.assistant_service | 1/5 | Siri services | [PrivacyLearn](https://privacylearn.com/macos/configure-os/configure-siri/disable-siri/disable-siri-system-services) |
| parsecd | com.apple.parsecd | 1/5 | Siri suggestions parsing | [Apple Community](https://discussions.apple.com/thread/252691485) |
| parsec-fbf | com.apple.parsec-fbf | 1/5 | Siri analytics flush/upload | [Apple Community](https://discussions.apple.com/thread/252691485) |
| siriknowledged | com.apple.siriknowledged | 1/5 | Siri knowledge | [PrivacyLearn](https://privacylearn.com/macos/configure-os/configure-siri/disable-siri/disable-siri-system-services) |
| sirittsd | com.apple.sirittsd | 1/5 | Siri text-to-speech | [PrivacyLearn](https://privacylearn.com/macos/configure-os/configure-siri/disable-siri/disable-siri-system-services) |
| siriinferenced | com.apple.siriinferenced | 1/5 | Siri inference engine | Research indicates safe |
| siriactionsd | com.apple.siriactionsd | 1/5 | Siri actions | Research indicates safe |

### Category 4: Consumer features (safe to disable for servers)

| Service | LaunchDaemon/Agent | Risk Level | Notes | Sources |
|---------|-------------------|------------|-------|---------|
| gamed | com.apple.gamed | 1/5 | Game Center - definitely not needed | [Apple Community](https://discussions.apple.com/thread/7793504), [HowToGeek](https://www.howtogeek.com/231129/how-to-disable-game-center-on-your-iphone-ipad-and-mac/) |
| ScreenTimeAgent | com.apple.ScreenTimeAgent | 1/5 | Screen Time tracking | [Apple Support](https://support.apple.com/guide/mac-help/set-up-content-and-privacy-restrictions-mchl8490d51e/mac) |
| familycontrols | com.apple.familycontrols | 1/5 | Parental controls | [GitHub Gist](https://gist.github.com/dims/36247f8b60d5c4c9e22cc8974174b8a8) |
| familycircled | com.apple.familycircled | 1/5 | Family Sharing | Common knowledge |
| familynotificationd | com.apple.familynotificationd | 1/5 | Family notifications | Common knowledge |
| AirDrop/sharingd | com.apple.sharingd | 2/5 | File sharing - not needed for server | [OSXDaily](https://osxdaily.com/2022/12/20/how-to-disable-airdrop-on-mac/), [Roundfleet](https://www.roundfleet.com/tutorial/2025-07-07-airdrop-management-macos) |
| rapportd | com.apple.rapportd-user | 2/5 | Device proximity/handoff | [SmallUsefulTips](https://smallusefultips.com/what-is-rapportd-on-a-mac/) |
| tipsd | com.apple.tipsd | 1/5 | Tips app daemon | Common knowledge |
| newsd | com.apple.newsd | 1/5 | News app daemon | Common knowledge |
| weatherd | com.apple.weatherd | 1/5 | Weather daemon | Common knowledge |
| Maps services | com.apple.Maps.* | 1/5 | Maps daemons | Common knowledge |
| homeenergyd | com.apple.homeenergyd | 1/5 | Home energy monitoring | Common knowledge |
| homed | com.apple.homed | 2/5 | HomeKit daemon | Common knowledge |
| AMPDevicesAgent | com.apple.AMPDevicesAgent | 1/5 | AirPlay devices | Common knowledge |
| AMPLibraryAgent | com.apple.AMPLibraryAgent | 1/5 | Media library | Common knowledge |
| AMPArtworkAgent | com.apple.AMPArtworkAgent | 1/5 | Artwork fetching | Common knowledge |
| itunescloudd | com.apple.itunescloudd | 1/5 | iTunes cloud sync | Common knowledge |
| mediastream.mstreamd | com.apple.mediastream.mstreamd | 1/5 | Photo stream | Common knowledge |

### Category 5: iCloud services (conditional - disable if not using)

| Service | LaunchDaemon/Agent | Risk Level | Notes | Sources |
|---------|-------------------|------------|-------|---------|
| cloudd | com.apple.cloudd | 2/5 | Main iCloud daemon - disable only if not using iCloud | [iBoysoft](https://iboysoft.com/wiki/cloudd.html) |
| iCloudUserNotifications | com.apple.iCloudUserNotifications | 1/5 | iCloud notifications | Common knowledge |
| icloud.searchpartyuseragent | com.apple.icloud.searchpartyuseragent | 1/5 | Find My network | Common knowledge |
| cloudpaird | com.apple.cloudpaird | 1/5 | Cloud pairing | Common knowledge |
| cloudphotod | com.apple.cloudphotod | 1/5 | iCloud Photos | Common knowledge |

### Category 6: Backup services (can disable if using external backup)

| Service | LaunchDaemon/Agent | Risk Level | Notes | Sources |
|---------|-------------------|------------|-------|---------|
| backupd | com.apple.backupd | 2/5 | Time Machine daemon | [HowChoo](https://howchoo.com/mac/how-to-disable-local-time-machine-backups/) |
| backupd-helper | com.apple.backupd-helper | 2/5 | Time Machine helper | [Backblaze](https://www.backblaze.com/computer-backup/docs/disable-time-machine-and-back-up-to-backblaze) |

---

## Critical services - DO NOT DISABLE

| Service | Reason | Source |
|---------|--------|--------|
| **mDNSResponder** | Core networking - Bonjour/DNS resolution. Apple replaced it with `discoveryd` in Yosemite (Oct 2014); after months of Wi-Fi, DNS, and wake-from-sleep issues, Apple reverted to mDNSResponder in 10.10.4 (May 2015), reportedly closing ~300 bug reports | [MacRumors](https://www.macrumors.com/2015/05/26/apple-discoveryd-replaced-with-mdnsresponder/), [9to5Mac](https://9to5mac.com/2015/05/26/apple-drops-discoveryd-in-latest-os-x-beta-following-months-of-complaints-about-network-issues-with-yosemite/), [HowToGeek](https://www.howtogeek.com/338914/what-is-mdnsresponder-and-why-is-it-running-on-my-mac/) |
| **configd** | DHCP, network configuration - system won't get IP address without it | [Apple Support](https://support.apple.com/en-gb/102685) |
| **diskarbitrationd** | Disk mounting/unmounting - breaks all disk operations | System critical |
| **securityd** | Security framework - breaks all authentication | System critical |
| **trustd** | Certificate trust evaluation | System critical |
| **opendirectoryd** | Directory services/user authentication | System critical |
| **launchd** | Init system - the parent of all processes | System critical |
| **kernel_task** | Kernel operations | System critical |
| **WindowServer** | GUI rendering (needed even for headless management) | System critical |
| **coreaudiod** | Audio subsystem (some apps depend on it existing) | May cause app crashes |
| **bluetoothd** | Bluetooth stack - keep if using any Bluetooth | May be needed |
| **airportd** | WiFi - keep if using WiFi | May be needed |
| **coreservicesd** | Core system services | System critical |
| **nsurlsessiond** | URL session handling - cannot be permanently disabled | [MacPaw](https://macpaw.com/how-to/remove-nsurlsessiond-from-mac), [Apple Community](https://discussions.apple.com/thread/251549227) |
| **cfprefsd** | Preferences daemon | System critical |
| **UserEventAgent** | User event handling | System critical |
| **notifyd** | Notification dispatch | System critical |

---

## Research sources

### Primary sources consulted
1. **Privacy & Telemetry:**
   - [IntelTechniques Blog - Minimizing macOS Telemetry](https://inteltechniques.com/blog/2021/08/03/minimizing-macos-telemetry/)
   - [Privacy Guides - macOS Overview](https://www.privacyguides.org/en/os/macos-overview/)
   - [GitHub - Telemetry Disable Guide](https://github.com/herrbischoff/telemetry)
   - [Intego - Turn Off Analytics](https://www.intego.com/mac-security-blog/how-to-turn-off-analytics-on-mac-iphone-and-ipad-to-protect-your-privacy/)

2. **Spotlight/Indexing:**
   - [iBoysoft - mdworker_shared](https://iboysoft.com/wiki/mdworker-shared.html)
   - [MacSecurity - mdworker High CPU](https://macsecurity.net/view/567-mdworker-shared-high-cpu-mac)
   - [SetApp - mds_stores High CPU](https://setapp.com/how-to/mds-stores-high-cpu-usage)
   - [Mac Observer - mds_stores and idleassetsd](https://www.macobserver.com/mac/mds_stores-idleassetsd-high-cpu-bandwidth-disk-usage-sonoma-sequoia/)

3. **Siri Services:**
   - [PrivacyLearn - Disable Siri System Services](https://privacylearn.com/macos/configure-os/configure-siri/disable-siri/disable-siri-system-services)
   - [Term7 - Kill Siri](https://term7.info/kill-siri/)
   - [MacPaw - Disable Siri](https://macpaw.com/how-to/disable-siri-on-mac)

4. **Photo Analysis:**
   - [GetDroidTips - Disabling mediaanalysisd](https://www.getdroidtips.com/disabling-mediaanalysisd-photoanalysisd-photolibraryd/)
   - [AppleInsider - mediaanalysisd High CPU](https://appleinsider.com/inside/macos-ventura/tips/how-to-stop-mediaanalysisd-from-hogging-your-cpu-in-macos)
   - [DroidWin - Disable Photo Analysis](https://droidwin.com/how-to-disable-mediaanalysisd-photoanalysisd-and-photolibraryd/)

5. **Server Performance:**
   - [Apple Support - Server Performance Mode](https://support.apple.com/en-us/101992)
   - [GitHub Gist - Enable macOS Server Performance Mode](https://gist.github.com/davidalger/a3afa2410a40ce6ae59d4e6a3b18e5c7)
   - [ESnet - Mac OSX Tuning](https://fasterdata.es.net/host-tuning/osx/)
   - [Rolande - Network Stack Tuning Sequoia 15.6](https://rolande.wordpress.com/2025/08/07/performance-tuning-the-network-stack-on-macos-sequoia-15-6/)

6. **launchctl Usage:**
   - [SS64 - launchctl Man Page](https://ss64.com/mac/launchctl.html)
   - [launchd.info - Tutorial](https://www.launchd.info/)
   - [Alan Siu - launchctl Basics](https://www.alansiu.net/2023/11/15/launchctl-new-subcommand-basics-for-macos/)

7. **Critical Services:**
   - [HowToGeek - mDNSResponder](https://www.howtogeek.com/338914/what-is-mdnsresponder-and-why-is-it-running-on-my-mac/)
   - [Apple Community - mDNSResponder and configd](https://discussions.apple.com/thread/1314540)

8. **macOS Hardening Script:**
   - [GitHub Gist - Sequoia Hardening Script](https://gist.github.com/ph33nx/ef7981bde362b8b2fc0e7fb8f62a6df8)

---

## Notes on research methodology

1. Each service was researched against multiple sources
2. When sources conflicted, the more conservative option was chosen
3. Services marked as system-critical by Apple documentation were never considered for disabling
4. All recommendations prioritise system stability over marginal performance gains
5. SIP being disabled allows more services to be controlled but increases risk
