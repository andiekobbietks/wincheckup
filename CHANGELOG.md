# Changelog

## 0.1.0 - 2026-11-05

First commit.

- Read-only Windows health check: system summary, OS support status, storage,
  devices in an error state, pending restart, update history, battery health.
- Driver audit: compares the driver bound to each device against newer packages
  already staged in the driver store, accounting for hardware-ID ranking. This
  is the finding the tool exists for.
- Third-party driver signature check, reported as information only.
- Virtual/software devices (VMware, Wi-Fi Direct) separated from real hardware.
- Inbox Microsoft drivers excluded from the "staged but unused" check.

Six false positives were found on the first run against a real machine and fixed
before this release: a graphics INF matched against an audio bus (device class
now required to match), an inbox USB driver flagged as outdated, virtual
adapters reported as failing hardware, a missed laptop battery, an Intel
placeholder driver date treated as a real age, and the computer name redacted as
if it were a serial number.