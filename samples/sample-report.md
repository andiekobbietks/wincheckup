# WinCheckup report

Generated 2026-11-05 12:56 on REDACTED-PC.

> Read-only check. Nothing on this machine was changed.

## Findings

| Severity | Finding | What to do |
|---|---|---|
| **HIGH** | Drive C: is nearly full. Only 2.47 GB free (1%). | Clear space before installing updates. Windows needs room to work. |
| **HIGH** | Windows build is out of support. Build 19045 reached end of servicing on 2025-10-14. | Check whether this PC can move to a supported Windows version. An in-place upgrade keeps apps and files. |
| **MEDIUM** | A restart is pending. Signals: File operations queued | Restart to finish applying updates or driver changes. Nothing is broken; it is simply not finished. |
| **MEDIUM** | Low memory. Installed RAM is 7.7 GB. | If the machine supports it, adding RAM is usually the cheapest speed-up. |

Severity: **HIGH** = act now, **MEDIUM** = worth fixing soon, **LOW** = minor, **INFO** = for information.

---


## System

| Item | Value |
|---|---|
| Computer | REDACTED-PC |
| User | REDACTED-USER |
| Model | ASUSTeK COMPUTER INC. VivoBook_ASUSLaptop X513EA_X513EA |
| CPU | 11th Gen Intel(R) Core(TM) i5-1135G7 @ 2.40GHz |
| RAM | 7.70 GB |
| OS | Microsoft Windows 10 Home |
| Version | 10.0.19045 (build 19045) |
| BIOS | X513EA.317 (2023-05-09) |
| Uptime | 2d 5h 32m |
| Report time | 2026-11-05 12:55 |

## Operating system support

- **Out of support.** Microsoft's published end of servicing for this build is 2025-10-14 (388 days ago).
- Security updates have stopped. Options: upgrade the OS, or accept the risk knowingly.

## Storage

| Drive | Size | Free | Free % |
|---|---|---|---|
| C: | 236.8 GB | 2.47 GB | 1% |

| Physical disk | Type | Health | State | Size |
|---|---|---|---|---|
| NVMe WDC PC SN530 SDBPNPZ-256G-1002 | SSD | Healthy | OK | 238.5 GB |

## Devices with problems

- No hardware device is in an error state.

- 3 virtual/software devices are in a non-OK state (usually harmless: leftover virtual adapters):
  - VMware Virtual Ethernet Adapter for VMnet1 (Error)
  - VMware Virtual Ethernet Adapter for VMnet8 (Error)
  - Microsoft Wi-Fi Direct Virtual Adapter #3 (Error)

## Pending restart

- A restart is pending (File operations queued).

## Recently installed updates

| Update | Description | Installed |
|---|---|---|
| KB5126256 | Security Update | 2026-09-19 |
| KB5071959 | Security Update | 2026-09-07 |
| KB5072653 | Security Update | 2026-09-07 |
| KB5071982 | Security Update | 2026-06-09 |
| KB5066130 | Update | 2025-11-15 |

## Battery

- Battery present: ASUS Battery
- Charge: 100%
- Capacity health is not exposed on this system.

## Driver audit

- 143 devices checked across 171 published driver packages.
- No device is sitting on an older driver while a newer staged package exists.

- 17 third-party devices use a driver dated more than five years ago. Published dates are not a reliable health signal on their own (the newest available driver is often years old), so this is counted, not listed.

- No third-party driver reports as unsigned.