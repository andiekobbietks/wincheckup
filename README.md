# WinCheckup

A **read-only** health check for Windows PCs. One PowerShell script. No installer,
no account, no telemetry, no network access. It looks at the machine and writes a
plain-English report.

> **Status: pre-release, private.** This repository is private while the tool is
> tested on real machines. The intent is to publish the core script under MIT
> once it has run clean on hardware beyond the single laptop it was written on.
> Nothing here is a released product yet.

```powershell
powershell -ExecutionPolicy Bypass -File .\Invoke-WinCheckup.ps1
```

That writes `WinCheckup-Report.md` next to the script and prints the report to
the console. To keep the personal details out of a report you plan to share:

```powershell
powershell -ExecutionPolicy Bypass -File .\Invoke-WinCheckup.ps1 -Anonymise
```

Runs on Windows PowerShell 5.1 (built into Windows 10 and 11) and on
PowerShell 7. Administrator rights are **not** required.

## What it checks

1. **Operating system support** -- build number against Microsoft's published end of servicing.
2. **Storage** -- free space per drive, physical disk health.
3. **Devices with problems** -- anything not in an `OK` state.
4. **Pending restart** -- whether updates or driver changes are waiting to finish.
5. **Update history** -- when the machine last took an update.
6. **Battery** -- full-charge capacity against design capacity.
7. **Driver audit** -- see below.
8. **Driver signatures** -- any third-party driver reporting as unsigned.

Everything above is a read from WMI/CIM, the registry, and the PnP subsystem.
The script writes exactly one file: the report you asked for.

## The driver audit (the interesting part)

Most tools answer "are my drivers up to date?" by comparing version numbers
against a vendor list. That check misses a failure mode that is common on
OEM laptops:

> Windows ranks **hardware-ID specificity above driver version**. If the
> original OEM driver INF matches a more specific hardware ID (for example
> `PCI\VEN_8086&DEV_9A49&SUBSYS_14321043`) and a newer WHQL driver INF matches
> only the generic ID (`PCI\VEN_8086&DEV_9A49`), Windows keeps the **older,
> more specific** match. The newer driver can already be sitting on disk, fully
> signed, and still not be the one in use.

WinCheckup indexes every published third-party driver package in
`C:\Windows\INF\oem*.inf`, extracts the hardware IDs each one supports, its
device class and its version, then compares that against the driver actually
bound to each device. If a newer package in the same device class supports the
same hardware ID as the bound one, the report says so, by name:

```
| Device                  | In use      | Staged, newer | Hardware ID            |
|-------------------------|-------------|---------------|------------------------|
| Intel(R) Iris(R) Xe ... | 27.20.100.9268 (oem46.inf) | 32.0.101.7092 (oem2.inf) | PCI\VEN_8086&DEV_9A49 |
```

That is the whole reason this exists. No download is implied by the finding: it
means the right driver is present and the machine is not using it.

## Reading the report

Findings are graded:

| Severity | Meaning |
|---|---|
| **HIGH** | Act now (out of support, failing disk, no updates in 90 days) |
| **MEDIUM** | Worth fixing soon (newer driver unused, restart pending, low space) |
| **LOW** | Minor |
| **INFO** | For information only, such as a driver reporting as unsigned |

A sample anonymised report is in [`samples/sample-report.md`](samples/sample-report.md).

## What it is not

- Not a driver updater. It never installs anything. It tells you what is true.
- Not an antivirus. It does not scan for malware, block anything, or monitor.
- Not a tuner or a debloater. It reads; it does not change.
- Not a guarantee. It only reports what the operating system exposes.

The report covers **staleness, space and drivers**. It does not cover malware,
backups, passwords, encryption or network security, and should never be sold as
if it did.

## Design decisions

**Read-only, on purpose.** A tool that changes the system cannot be handed to a
non-technical person without risk, and cannot be trusted by default. Reading is
what makes it safe to run anywhere. The output is a decision for a human, not an
automated change.

**MIT the code, keep the brand.** The code is a commodity; the trust is not.
Open-core projects fail when someone re-sells *your identity*, not when they fork
your code.

**Private now, open later.** A private repository and a "free, one-line, anyone
can run it" distribution model cannot both be true at once. The repository is
private while the tool is unproven; the plan is to open the core once it is.

**Why the report is Markdown.** Plain text, diffable, readable in any editor,
and trivially converted to PDF for a client who wants a document.

## How this started

This was not designed on a whiteboard. It came out of a repair on one laptop: an
ASUS VivoBook X513EA (11th-gen i5, Windows 10 Home, build 19045).

The job began as a driver backup before a possible Windows 11 upgrade. While
auditing the machine, the Intel graphics device was found running
`27.20.100.9268`, bound to an OEM INF dated **2021**. A signed
`32.0.101.7092` package was already sitting in the driver store, unused.

The obvious fix failed. `pnputil /add-driver /install` refused with
*"Driver package is up-to-date on device"* -- because Windows considered the
installed one correct. The cause was hardware-ID ranking: the 2021 OEM INF
matched `PCI\VEN_8086&DEV_9A49&SUBSYS_14321043`, more specific than the newer
package's generic `PCI\VEN_8086&DEV_9A49`, and Windows prefers the more specific
match over the newer version.

Every tool consulted -- including Windows' own -- said the machine was up to
date. It was not. The driver was forced in with
`UpdateDriverForPlugAndPlayDevices` and `INSTALLFLAG_FORCE`, run elevated, and
the device came up on the 2026 driver with `rebootRequired=False`.

The lesson was not "one laptop had a stale driver". It was that an entire class
of misconfiguration is invisible to the tools people already use, and that the
people most likely to be affected are the least equipped to notice. WinCheckup is
the read-only check that would have found it in seventy seconds.

## Running this as a paid service

It can be turned into a domestic service: a monthly read-only check plus the
human work of acting on it. The reasoning, the per-visit work, the things that
must never be promised, and the legal exposure are written up in
[`docs/service-model.md`](docs/service-model.md).

The short version: the scan is nearly free, the fix is the labour, and the tool
is not a security product.

## Licence

MIT -- see [`LICENCE`](LICENCE). Use it, fork it, ship it.