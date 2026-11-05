<#
.SYNOPSIS
    WinCheckup - a free, read-only health check for Windows PCs.

.DESCRIPTION
    Inspects the machine and writes a plain-English report. It does NOT change
    anything: no driver installs, no registry writes, no settings. Safe to run
    on Windows 10 or 11, elevated or not.

    The most useful check is the driver audit. It compares the driver actually
    bound to each device against other driver packages already staged in the
    Windows driver store. Windows ranks hardware IDs above version numbers, so
    a machine can sit on a years-old OEM driver while a newer WHQL-signed one
    is already on disk. Most tools report "up to date" in that case.

.PARAMETER OutFile
    Path for the Markdown report. Defaults to .\WinCheckup-Report.md

.PARAMETER Anonymise
    Replace the computer name, user name, serial numbers and MAC addresses in
    the written report. Use this before sharing a sample.

.PARAMETER NoConsole
    Write the report file but do not echo it to the console.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Invoke-WinCheckup.ps1 -Anonymise

.NOTES
    Licence: MIT. Read-only. No telemetry. No network access.
#>
[CmdletBinding()]
param(
    [string]$OutFile,
    [switch]$Anonymise,
    [switch]$NoConsole
)

$ErrorActionPreference = 'Continue'
Set-StrictMode -Off

if (-not $OutFile) { $OutFile = Join-Path (Get-Location) 'WinCheckup-Report.md' }

# ------------------------------------------------------------------ scaffolding
$script:Rows     = New-Object System.Collections.Generic.List[string]
$script:Findings = New-Object System.Collections.Generic.List[object]

function W([string]$s) {
    if (-not $NoConsole) { Write-Host $s }
    $script:Rows.Add([string]$s)
}
function Blank { W '' }
function H1([string]$s) { Blank; W "# $s"; Blank }
function H2([string]$s) { Blank; W "## $s"; Blank }
function P([string]$s) { W $s }

function Add-Finding {
    param(
        [ValidateSet('HIGH','MEDIUM','LOW','INFO')][string]$Severity,
        [string]$Title,
        [string]$Detail,
        [string]$Action
    )
    $script:Findings.Add([pscustomobject]@{
        Severity = $Severity
        Title    = $Title
        Detail   = $Detail
        Action   = $Action
    })
}

function Try-Get {
    param([scriptblock]$Block, $Default = $null)
    try { & $Block } catch { $Default }
}

function Format-GB($bytes) {
    if ($null -eq $bytes) { return 'n/a' }
    '{0:N2} GB' -f ($bytes / 1GB)
}

function Plural([int]$n, [string]$word) {
    if ($n -eq 1) { return $word }
    return "${word}s"
}

function Test-VirtualDevice($dev) {
    if (-not $dev) { return $false }
    $id = [string]$dev.InstanceId
    $nm = [string]$dev.FriendlyName
    if ($id -like 'ROOT\*' -or $id -like 'SWD\*' -or $id.StartsWith('{')) { return $true }
    if ($nm -match 'Virtual|Hyper-V|Loopback|TAP-|WAN Miniport') { return $true }
    return $false
}

# --------------------------------------------------------------- identity bits
$script:Identity = @{
    Computer = $env:COMPUTERNAME
    User     = $env:USERNAME
    Serials  = @()
    Macs     = @()
}

function Get-SafeString([object]$v) {
    if ($null -eq $v) { return 'n/a' }
    $s = ([string]$v).Trim()
    if ([string]::IsNullOrWhiteSpace($s)) { return 'n/a' }
    $s
}

# =================================================================== 1. SYSTEM
H2 'System'

$os      = Try-Get { Get-CimInstance Win32_OperatingSystem }
$cs      = Try-Get { Get-CimInstance Win32_ComputerSystem }
$bios    = Try-Get { Get-CimInstance Win32_BIOS }
$cpu     = Try-Get { Get-CimInstance Win32_Processor | Select-Object -First 1 }

$build      = if ($os) { [int]$os.BuildNumber } else { 0 }
$caption    = Get-SafeString $os.Caption
$versionStr = Get-SafeString $os.Version
$displayVer = Get-SafeString $os.Version

$script:Identity.Serials += @($bios.SerialNumber) | Where-Object { $_ }
$script:Identity.Serials += (Try-Get { (Get-CimInstance Win32_BaseBoard).SerialNumber })

$model  = Get-SafeString $cs.Model
$vendor = Get-SafeString $cs.Manufacturer
$biosV  = Get-SafeString $bios.SMBIOSBIOSVersion
$biosD  = if ($bios) { (Try-Get { $bios.ReleaseDate.ToString('yyyy-MM-dd') }) } else { 'n/a' }
$cpuN   = Get-SafeString $cpu.Name

$ramB   = if ($cs) { [int64]$cs.TotalPhysicalMemory } else { 0 }
$up     = if ($os) { (Get-Date) - $os.LastBootUpTime } else { $null }
$upStr  = if ($up) { '{0}d {1}h {2}m' -f $up.Days, $up.Hours, $up.Minutes } else { 'n/a' }

P "| Item | Value |"
P "|---|---|"
P "| Computer | $($script:Identity.Computer) |"
P "| User | $($script:Identity.User) |"
P "| Model | $vendor $model |"
P "| CPU | $cpuN |"
P "| RAM | $(Format-GB $ramB) |"
P "| OS | $caption |"
P "| Version | $versionStr (build $build) |"
P "| BIOS | $biosV ($biosD) |"
P "| Uptime | $upStr |"
P "| Report time | $(Get-Date -Format 'yyyy-MM-dd HH:mm') |"

# ---- servicing / support status -----------------------------------------
$eolTable = @{
    19041 = '2025-10-14'; 19042 = '2025-10-14'; 19043 = '2025-10-14'
    19044 = '2025-10-14'; 19045 = '2025-10-14'
    22000 = '2023-10-10'; 22621 = '2025-11-11'; 22631 = '2026-11-11'
    26100 = '2027-10-12'
}
$eol = $null
if ($eolTable.ContainsKey($build)) { $eol = $eolTable[$build] }

H2 'Operating system support'

if ($eol) {
    $eolDate = [datetime]::ParseExact($eol, 'yyyy-MM-dd', $null)
    $days    = [int]($eolDate - (Get-Date)).TotalDays
    if ($days -lt 0) {
        P "- **Out of support.** Microsoft's published end of servicing for this build is $eol ($([math]::Abs($days)) days ago)."
        P "- Security updates have stopped. Options: upgrade the OS, or accept the risk knowingly."
        Add-Finding -Severity 'HIGH' -Title 'Windows build is out of support' `
            -Detail "Build $build reached end of servicing on $eol." `
            -Action 'Check whether this PC can move to a supported Windows version. An in-place upgrade keeps apps and files.'
    } else {
        P "- In support until $eol ($days days remaining)."
    }
} else {
    P "- Build $build is not in the built-in table. Check Microsoft's lifecycle page for this build."
}

# ---- RAM / capacity sanity ----------------------------------------------
if ($ramB -gt 0 -and $ramB -lt 8GB) {
    Add-Finding -Severity 'MEDIUM' -Title 'Low memory' `
        -Detail ("Installed RAM is {0:N1} GB." -f ($ramB/1GB)) `
        -Action 'If the machine supports it, adding RAM is usually the cheapest speed-up.'
}

# ================================================================== 2. STORAGE
H2 'Storage'

$disks = @(Try-Get { Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' } @())
if ($disks.Count -gt 0) {
    P "| Drive | Size | Free | Free % |"
    P "|---|---|---|---|"
    foreach ($d in $disks) {
        $pct = if ($d.Size -gt 0) { [math]::Round(100 * $d.FreeSpace / $d.Size, 1) } else { 0 }
        P ("| {0} | {1:N1} GB | {2:N2} GB | {3}% |" -f $d.DeviceID, ($d.Size/1GB), ($d.FreeSpace/1GB), $pct)
        if ($pct -lt 10) {
            Add-Finding -Severity 'HIGH' -Title ("Drive {0} is nearly full" -f $d.DeviceID) `
                -Detail ("Only {0:N2} GB free ({1}%)." -f ($d.FreeSpace/1GB), $pct) `
                -Action 'Clear space before installing updates. Windows needs room to work.'
        } elseif ($pct -lt 15) {
            Add-Finding -Severity 'MEDIUM' -Title ("Drive {0} is low on space" -f $d.DeviceID) `
                -Detail ("{0:N2} GB free ({1}%)." -f ($d.FreeSpace/1GB), $pct) `
                -Action 'Worth freeing space when convenient.'
        }
    }
} else {
    P '- No fixed disks reported.'
}

$phys = @(Try-Get { Get-PhysicalDisk } @())
if ($phys.Count -gt 0) {
    P ''
    P "| Physical disk | Type | Health | State | Size |"
    P "|---|---|---|---|---|"
    foreach ($pd in $phys) {
        P ("| {0} | {1} | {2} | {3} | {4:N1} GB |" -f $pd.FriendlyName, $pd.MediaType, $pd.HealthStatus, $pd.OperationalStatus, ($pd.Size/1GB))
        if ($pd.HealthStatus -ne 'Healthy') {
            Add-Finding -Severity 'HIGH' -Title 'Disk reports a health problem' `
                -Detail ("{0}: health={1}, state={2}." -f $pd.FriendlyName, $pd.HealthStatus, $pd.OperationalStatus) `
                -Action 'Back up now. A failing drive is the one problem that loses data rather than time.'
        }
    }
} else {
    P ''
    P '- Physical disk health not available on this system.'
}

# ================================================================== 3. DEVICES
H2 'Devices with problems'

$pnp = @(Try-Get { Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue } @())
$problemAll = @($pnp | Where-Object { $_.Status -and $_.Status -ne 'OK' })
# Software and virtual devices (VMware adapters, Wi-Fi Direct, ...) live under
# ROOT\ or SWD\. They routinely sit in Error state on healthy machines, so they
# are reported separately from real hardware.
$problem        = @($problemAll | Where-Object { -not (Test-VirtualDevice $_) })
$virtualProblem = @($problemAll | Where-Object { Test-VirtualDevice $_ })

if ($problem.Count -eq 0) {
    P '- No hardware device is in an error state.'
} else {
    P "| Device | Class | Status |"
    P "|---|---|---|"
    foreach ($d in $problem) {
        P ("| {0} | {1} | {2} |" -f $d.FriendlyName, $d.Class, $d.Status)
    }
    $errCount = @($problem | Where-Object { $_.Status -eq 'Error' }).Count
    Add-Finding -Severity $(if ($errCount -gt 0) { 'HIGH' } else { 'MEDIUM' }) `
        -Title ("{0} {1} not in a healthy state" -f $problem.Count, (Plural $problem.Count 'device')) `
        -Detail (($problem | ForEach-Object { $_.FriendlyName }) -join '; ') `
        -Action 'Devices showing Error usually need a driver. Reinstall the vendor driver for that device.'
}

if ($virtualProblem.Count -gt 0) {
    P ''
    $vVerb = if ($virtualProblem.Count -eq 1) { 'device is' } else { 'devices are' }
    P ("- {0} virtual/software {1} in a non-OK state (usually harmless: leftover virtual adapters):" -f $virtualProblem.Count, $vVerb)
    foreach ($v in ($virtualProblem | Select-Object -First 5)) {
        P ("  - {0} ({1})" -f $v.FriendlyName, $v.Status)
    }
}

# ============================================================= 4. PENDING REBOOT
H2 'Pending restart'

$reboot = @()
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $reboot += 'Component Based Servicing' }
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $reboot += 'Windows Update' }
if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations') { $reboot += 'Pending file rename' }
$pfro = Try-Get { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue).PendingFileRenameOperations }
if ($pfro) { $reboot += 'File operations queued' }
$reboot = $reboot | Select-Object -Unique

if ($reboot.Count -eq 0) {
    P '- No restart pending.'
} else {
    P ("- A restart is pending ({0})." -f ($reboot -join ', '))
    Add-Finding -Severity 'MEDIUM' -Title 'A restart is pending' `
        -Detail ('Signals: ' + ($reboot -join ', ')) `
        -Action 'Restart to finish applying updates or driver changes. Nothing is broken; it is simply not finished.'
}

# ================================================================== 5. UPDATES
H2 'Recently installed updates'

$hf = @(Try-Get { Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 5 } @())
if ($hf.Count -gt 0) {
    P "| Update | Description | Installed |"
    P "|---|---|---|"
    foreach ($h in $hf) {
        $d = if ($h.InstalledOn) { $h.InstalledOn.ToString('yyyy-MM-dd') } else { 'n/a' }
        P ("| {0} | {1} | {2} |" -f $h.HotFixID, $h.Description, $d)
    }
    $newest = $hf | Where-Object { $_.InstalledOn } | Select-Object -First 1
    if ($newest) {
        $age = [int]((Get-Date) - $newest.InstalledOn).TotalDays
        if ($age -gt 90) {
            Add-Finding -Severity 'HIGH' -Title 'No update installed in over 90 days' `
                -Detail ("Newest recorded update was {0} days ago." -f $age) `
                -Action 'Run Windows Update. Missing updates are how most malware gets in.'
        }
    }
} else {
    P '- Update history not readable.'
}

# ================================================================== 6. BATTERY
H2 'Battery'

$static = Try-Get { Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue }
$full   = Try-Get { Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue }
$wb     = Try-Get { Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue }

$design  = $null
$fullCap = $null
if ($static -and $full -and $static.DesignedCapacity -gt 0) {
    $design  = $static.DesignedCapacity
    $fullCap = $full.FullChargedCapacity
} elseif ($wb -and $wb.DesignCapacity -gt 0) {
    $design  = $wb.DesignCapacity
    $fullCap = $wb.FullChargeCapacity
}

if ($design -gt 0 -and $fullCap -gt 0) {
    $health = [math]::Round(100 * $fullCap / $design, 1)
    P ("- Design capacity: {0} mWh" -f $design)
    P ("- Current full-charge capacity: {0} mWh" -f $fullCap)
    P ("- Health: **{0}% of design capacity**" -f $health)
    if ($health -lt 60) {
        Add-Finding -Severity 'MEDIUM' -Title 'Battery has degraded' `
            -Detail ("Holds {0}% of its original capacity." -f $health) `
            -Action 'Expect short runtimes off mains. Replacement is the only real fix.'
    }
} elseif ($wb) {
    P ("- Battery present: {0}" -f (Get-SafeString $wb.Name))
    P ("- Charge: {0}%" -f $wb.EstimatedChargeRemaining)
    P '- Capacity health is not exposed on this system.'
} else {
    P '- No battery detected (desktop, or battery data not exposed).'
}

# ============================================================ 7. DRIVER AUDIT
H2 'Driver audit'

# Build an index of every published OEM driver INF: version + the hardware IDs
# it supports. One pass over C:\Windows\INF\oem*.inf.
function Get-BaseHardwareId([string]$hw) {
    if (-not $hw) { return '' }
    $s = $hw.Trim().ToUpper()
    $s = $s -replace '&SUBSYS_[0-9A-F]+', ''
    $s = $s -replace '&REV_[0-9A-F]+', ''
    $s = $s.TrimStart('\').TrimEnd('\')
    return $s
}

function Compare-DriverVersion([string]$a, [string]$b) {
    # returns -1, 0, 1 for a < b, a == b, a > b
    $va = $null; $vb = $null
    if (-not [version]::TryParse($a, [ref]$va)) { return 0 }
    if (-not [version]::TryParse($b, [ref]$vb)) { return 0 }
    return $va.CompareTo($vb)
}

if (-not $NoConsole) { Write-Host 'Indexing driver store...' -ForegroundColor DarkGray }

$infDir   = Join-Path $env:windir 'INF'
$infFiles = @(Try-Get { Get-ChildItem $infDir -Filter 'oem*.inf' -File -ErrorAction SilentlyContinue } @())
$idRx     = [regex]'(?i)(PCI|USB|HDAUDIO|ACPI)\\(?:VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}|VID_[0-9A-F]{4}&PID_[0-9A-F]{4})'
$verRx    = [regex]'(?i)^\s*DriverVer\s*=\s*[\d/]+\s*,\s*([\d\.]+)'
$clsRx    = [regex]'(?i)^\s*ClassGUID\s*=\s*\{([0-9A-Fa-f\-]+)\}'
$infIndex = @{}

foreach ($f in $infFiles) {
    $ver = $null
    $cls = $null
    $ids = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($line in [IO.File]::ReadLines($f.FullName)) {
        if (-not $ver) {
            $m = $verRx.Match($line)
            if ($m.Success) { $ver = $m.Groups[1].Value }
        }
        if (-not $cls) {
            $mc = $clsRx.Match($line)
            if ($mc.Success) { $cls = $mc.Groups[1].Value.ToUpper() }
        }
        if ($line -match '\\') {
            foreach ($mm in $idRx.Matches($line)) {
                [void]$ids.Add((Get-BaseHardwareId $mm.Value))
            }
        }
    }
    $infIndex[$f.Name] = [pscustomobject]@{ Version = $ver; Class = $cls; Ids = $ids }
}

# Reverse map: base hardware ID -> INF names that support it
$byId = @{}
foreach ($k in $infIndex.Keys) {
    foreach ($id in $infIndex[$k].Ids) {
        if (-not $byId.ContainsKey($id)) { $byId[$id] = New-Object System.Collections.Generic.List[string] }
        $byId[$id].Add($k)
    }
}

$devices = @($pnp | Where-Object { $_.Status -eq 'OK' })
$mismatches = New-Object System.Collections.Generic.List[object]
$oldDrivers = New-Object System.Collections.Generic.List[object]
$fiveYears  = (Get-Date).AddYears(-5)

foreach ($d in $devices) {
    $infName = Try-Get { (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_DriverInfPath' -ErrorAction SilentlyContinue).Data }
    if ([string]::IsNullOrWhiteSpace($infName)) { continue }

    # Only third-party published packages (oem*.inf) are candidates. An inbox
    # Microsoft driver (usb.inf, pci.inf, ...) doing its job is not a problem,
    # and Windows never counts it as one either.
    if ($infName -notmatch '^oem\d+\.inf$') { continue }

    $devClass = Get-SafeString (Try-Get { $d.ClassGuid })
    $boundVer = Try-Get { (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_DriverVersion' -ErrorAction SilentlyContinue).Data }
    $boundDate = Try-Get { (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_DriverDate' -ErrorAction SilentlyContinue).Data }
    $prov = Try-Get { (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_DriverProvider' -ErrorAction SilentlyContinue).Data }

    $hwids = @(Try-Get { (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_HardwareIds' -ErrorAction SilentlyContinue).Data } @())
    $bases = @($hwids | ForEach-Object { Get-BaseHardwareId $_ } | Where-Object { $_ })

    $better = New-Object System.Collections.Generic.List[object]
    foreach ($bid in ($bases | Select-Object -Unique)) {
        if (-not $byId.ContainsKey($bid)) { continue }
        foreach ($cand in $byId[$bid]) {
            if ($cand -eq $infName) { continue }
            $ci = $infIndex[$cand]
            $cv = $ci.Version
            if (-not $cv -or -not $boundVer) { continue }
            # Same hardware ID and same device class, or it is not a substitute.
            if ($ci.Class -and $devClass -ne 'n/a' -and $ci.Class -ne $devClass) { continue }
            if ((Compare-DriverVersion $boundVer $cv) -lt 0) {
                $better.Add([pscustomobject]@{ Inf = $cand; Version = $cv; Id = $bid })
            }
        }
    }

    if ($better.Count -gt 0) {
        $best = $better | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1
        $mismatches.Add([pscustomobject]@{
            Device   = $d.FriendlyName
            Class    = $d.Class
            BoundInf = $infName
            BoundVer = $boundVer
            Better   = $best.Version
            BetterInf = $best.Inf
            HardwareId = $best.Id
            Provider = $prov
        })
    }

    # Intel and some vendors use 1968-07-18 as a placeholder date, so ignore
    # anything before 2000 rather than presenting a sentinel as a real age.
    if ($boundDate -and $boundDate -is [datetime] -and $boundDate -gt [datetime]'2000-01-01' -and $boundDate -lt $fiveYears) {
        $oldDrivers.Add([pscustomobject]@{ Device = $d.FriendlyName; Class = $d.Class; Date = $boundDate; Version = $boundVer; Inf = $infName })
    }
}

P ("- {0} {1} checked across {2} published driver {3}." -f $devices.Count, (Plural $devices.Count 'device'), $infFiles.Count, (Plural $infFiles.Count 'package'))

if ($mismatches.Count -eq 0) {
    P '- No device is sitting on an older driver while a newer staged package exists.'
} else {
    P ''
    $mVerb = if ($mismatches.Count -eq 1) { 'device has' } else { 'devices have' }
    P ("**{0} {1} a newer driver already on disk but not in use.**" -f $mismatches.Count, $mVerb)
    P ''
    P "| Device | In use | Staged, newer | Hardware ID |"
    P "|---|---|---|---|"
    foreach ($m in $mismatches) {
        P ("| {0} | {1} ({2}) | {3} ({4}) | {5} |" -f $m.Device, $m.BoundVer, $m.BoundInf, $m.Better, $m.BetterInf, $m.HardwareId)
    }
    Add-Finding -Severity 'MEDIUM' -Title 'Newer driver is on disk but not in use' `
        -Detail ("{0} {1} affected; first is {2} (uses {3}, newer {4} is staged)." -f $mismatches.Count, (Plural $mismatches.Count 'device'), $mismatches[0].Device, $mismatches[0].BoundVer, $mismatches[0].Better) `
        -Action 'Windows prefers the more specific OEM hardware ID over a newer version. This needs a deliberate driver update, not a download.'
}

if ($oldDrivers.Count -gt 0) {
    P ''
    $oldVerb = if ($oldDrivers.Count -eq 1) { 'device uses' } else { 'devices use' }
    P ("- {0} third-party {1} a driver dated more than five years ago. Published dates are not a reliable health signal on their own (the newest available driver is often years old), so this is counted, not listed." -f $oldDrivers.Count, $oldVerb)
}

# ---- signature check -----------------------------------------------------
# Win32_PnPSignedDriver's IsSigned flag is not authoritative, so this is
# reported as information, not as a defect, and only for third-party packages.
$signed = @(Try-Get { Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue } @())
$unsigned = @($signed | Where-Object {
    $_.IsSigned -eq $false -and
    $_.DriverProviderName -and
    $_.DriverProviderName -notmatch 'Microsoft' -and
    $_.InfName -match '^oem\d+\.inf$'
})
if ($unsigned.Count -gt 0) {
    P ''
    P ("- {0} third-party {1} report as unsigned. The operating system's flag is not always reliable, so treat this as a prompt to check, not a conclusion:" -f $unsigned.Count, (Plural $unsigned.Count 'driver'))
    foreach ($u in ($unsigned | Select-Object -First 10)) {
        P ("  - {0} ({1}, {2})" -f $u.DeviceName, $u.DriverProviderName, $u.InfName)
    }
    Add-Finding -Severity 'INFO' -Title 'Some third-party drivers report as unsigned' `
        -Detail ("{0} third-party {1} report as unsigned." -f $unsigned.Count, (Plural $unsigned.Count 'driver')) `
        -Action 'If you did not install these, identify them. The flag is a hint, not proof.'
} else {
    P ''
    P '- No third-party driver reports as unsigned.'
}

# ======================================================== 8. RECOMMENDATIONS
$order = @{ HIGH = 0; MEDIUM = 1; LOW = 2; INFO = 3 }
$findings = @($script:Findings | Sort-Object { $order[$_.Severity] })

$head = New-Object System.Collections.Generic.List[string]
$head.Add('# WinCheckup report')
$head.Add('')
$head.Add(('Generated {0} on {1}.' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $env:COMPUTERNAME))
$head.Add('')
$head.Add('> Read-only check. Nothing on this machine was changed.')
$head.Add('')
$head.Add('## Findings')
$head.Add('')

if ($findings.Count -eq 0) {
    $head.Add('No issues found by the checks in this report.')
} else {
    $head.Add('| Severity | Finding | What to do |')
    $head.Add('|---|---|---|')
    foreach ($f in $findings) {
        $head.Add(('| **{0}** | {1}. {2} | {3} |' -f $f.Severity, $f.Title, $f.Detail, $f.Action))
    }
}
$head.Add('')
$head.Add('Severity: **HIGH** = act now, **MEDIUM** = worth fixing soon, **LOW** = minor, **INFO** = for information.')
$head.Add('')
$head.Add('---')
$head.Add('')

$body = ($head + $script:Rows) -join "`r`n"

# ------------------------------------------------------------- anonymisation
if ($Anonymise) {
    $map = @{}
    if ($env:COMPUTERNAME) { $map[$env:COMPUTERNAME] = 'REDACTED-PC' }
    if ($env:USERNAME)     { $map[$env:USERNAME]     = 'REDACTED-USER' }
    foreach ($s in $script:Identity.Serials) {
        $t = ([string]$s).Trim()
        if ($t.Length -ge 6 -and $t -match '[0-9A-Za-z]' `
            -and $t -notmatch '^(None|Default string|To be filled|System Serial|O\.E\.M\.)' `
            -and $t -ne $env:COMPUTERNAME -and $t -ne $env:USERNAME) {
            $map[$t] = 'REDACTED-SERIAL'
        }
    }
    $macs = @(Try-Get { (Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=True' -ErrorAction SilentlyContinue).MACAddress } @())
    foreach ($m in $macs) {
        if ($m) { $map[([string]$m).Trim()] = 'REDACTED-MAC' }
    }
    foreach ($k in $map.Keys) {
        if ($k) { $body = $body -replace [regex]::Escape($k), $map[$k] }
    }
}

# ------------------------------------------------------------------ output
try {
    $dir = Split-Path -Parent $OutFile
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllText($OutFile, $body, (New-Object Text.UTF8Encoding($false)))
    Write-Host ''
    Write-Host ('Report written: {0}' -f (Resolve-Path $OutFile)) -ForegroundColor Green
} catch {
    Write-Host ('Could not write report: {0}' -f $_.Exception.Message) -ForegroundColor Red
}

$hi = @($findings | Where-Object { $_.Severity -eq 'HIGH' }).Count
$me = @($findings | Where-Object { $_.Severity -eq 'MEDIUM' }).Count
Write-Host ('Findings: {0} HIGH, {1} MEDIUM, {2} total.' -f $hi, $me, $findings.Count)