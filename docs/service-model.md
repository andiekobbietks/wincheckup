# Service model (working notes)

> Internal working notes for a possible paid service built on WinCheckup.
> Not a published offer. Not customer-facing copy.
>
> Section 5 now separates two things: **measured comparator prices** (published
> UK list prices, with source and date) and **judgement** (which band to price
> into). Comparators are other people's advertised prices, not what customers
> actually pay. Do not present the comparator median as your own price; it is a
> reference point.

## 1. What the report covers, and what it does not

This split is the whole honesty of the product. Sell the left column. Never
imply the right column.

| Covered (measured by the script) | Not covered (the report cannot tell you) |
|---|---|
| OS build against published end of servicing | Malware, ransomware, phishing |
| Disk free space, disk SMART health | Account compromise |
| Devices in an error state | Browser extensions and toolbars |
| Pending restart | Whether a backup exists |
| Age of the last installed update | Whether the disk is encrypted |
| Battery design vs current capacity | Network and router security |
| Driver bound older than a staged newer package | Weak or reused passwords |
| Third-party drivers reporting unsigned (info) | Physical theft of the machine |

The report is about **staleness, space and drivers**. It is not a security
product. It surfaces a handful of things antivirus does not look at; it does not
block, scan, patch or monitor.

## 2. The one failure mode worth selling

Windows ranks hardware-ID specificity above driver version. A device can sit on
a years-old OEM driver **while a newer, signed driver is already on disk**,
because the old INF matched a more specific hardware ID. This never
self-corrects. It is not "drift" -- nothing degrades on its own. It is a stable
misconfiguration that persists until a human deliberately forces the update.

Windows' own tools, and every consumer "driver updater", report such a machine
as up to date. This is the reason the tool exists and the one finding a
competent human can act on and charge for.

## 3. Per visit (what you actually do)

1. Run the report (~70 seconds, unattended).
2. Read it and translate it to the client in plain words.
3. **Confirm a backup exists before touching any driver.** No backup, no driver
   work.
4. Remediate, with the client's consent each step:
   - Install pending updates, then reboot.
   - Free disk space.
   - Update the driver where a newer package is already staged but unused.
   - Advise on battery replacement or an out-of-support OS.
5. Re-run the report to confirm the change.
6. Leave the report with the client (Markdown, or PDF on request).

The scan is nearly free. The labour is the fix, and it is open-ended: you do not
know what a machine needs until you run the report on it.

## 4. What you refuse to promise

Put this in writing, before money changes hands.

- Not a virus guarantee.
- Not "your data is safe" -- nothing here checks backups.
- Not recovery if a driver update goes wrong.
- Not privacy or encryption of their files.
- Not that the machine will not break.

Give the client both lists: what was checked, and what was not.

## 5. Charging (market comparators, then judgement)

Two layers, kept apart:

1. **Measured** -- what other UK domestic PC services advertise, below.
2. **Judgement** -- which band to price into. The comparator set informs it; it
   does not decide it.

### 5a. Comparators (measured: published list prices)

| Provider | Scope | Price | Source / read date |
|---|---|---|---|
| pcrepair2000 (NW London, mobile) | Minimum labour charge | from £50 | pcrepair2000.co.uk/prices.html, 2026-11-05 |
| pcrepair2000 | PC/laptop health check | from £60 | same |
| Which? Trusted Traders | General service (slow machine, no faults, 1-2 hrs) | £60 | trustedtraders.which.co.uk, updated Nov 2025, excl VAT |
| Checkatrade | Computer maintenance | £70 plus parts | checkatrade.com cost guide |
| KB Computer Repairs (Sussex, mobile, 2026 list) | Software home visit + install | from £89.99 | kbcomputerrepairs.co.uk, 2026 list |
| PC and Mac World (London) | Initial setup / Windows reinstall | £99 | pcandmacworld.co.uk/pricing |
| Currys (national) | Upfront computer repair fee | £50 | currys.co.uk, non-refundable |
| Checkatrade | Computer repair, per hour | £40/hr | same cost guide |
| pcrepair2000 | Labour, per hour | £80/hr | same price list |
| PC and Mac World | Remote support, per hour | ~£100/hr (£30 first 15 min, £25 each extra 15) | same pricing page |
| Checkatrade | Annual maintenance contract | £200/yr | same cost guide |
| KB Computer Repairs | Remote IT support (returning customers) | from £90 | same 2026 list |

Summary of the comparator set, computed from the table above:

- One-off service / health check / setup, n = 7: median £60, range £50-£99.
- Hourly labour, n = 3: median £80, range £40-£100.
- Annual maintenance contract, n = 1: £200 (Checkatrade). Monthly plans exist but are quoted, not published.

Caveats: these are advertised list prices, not transaction prices; several
exclude VAT; several are "from" prices that rise with parts, travel or evenings.
Currys' £50 is a deposit, refunded against a higher repair price.

### 5b. Applying it (judgement)

- **Per-visit fee** -- the first clean-up. One-off. The comparator median for a
  one-off service is £60 (range £50-£99); a mobile home-visit service sits at
  the upper end of that band. Position the first visit inside that band. This is
  a judgement, not a computed price.
- **Monthly retainer** -- the recurring check plus fixes. This is the actual
  business; the report is the receipt. The only published recurring figure found
  is a £200 annual maintenance contract (Checkatrade), a reference band rather
  than a rule.

The monthly cadence is a judgement, not a measurement. It fits what the tool
actually detects: the "no update in 90 days" flag cannot trip sooner than 90
days, the OS support date changes once every several years, and disk space
crosses a threshold gradually. Daily monitoring would be motion without value.
Comparators show recurring maintenance is an established product (annual
contracts, monthly plans), so the retainer is not a novel ask.

Do not price the scan. Price the human.

## 6. Legal and risk to settle before charging anyone

- **Data protection.** Holding client machine data brings GDPR and the UK Data
  Protection Act 2018 into play. A local read-only tool that never phones home is
  the easy case; a hosted dashboard that collects client data is not.
- **Liability.** You can break a machine with a driver update. Mitigate with a
  one-page agreement, a backup first, and insurance.
- **Insurance.** Check what professional indemnity covers before the first paid
  job.
- **Safeguarding.** If clients include vulnerable adults, DBS and safeguarding
  duties apply.

## 7. Open questions (unresolved)

- Is the first paid job for a known person (lowest legal exposure) or a
  stranger?
- Does the client want a document they keep, or a person who turns up?
- What does the local market charge for a comparable domestic visit? **Partly
  answered** -- see section 5a for the first comparator set (7 one-off prices, 3
  hourly rates, read 2026-11-05). Still to add: prices from shops physically near
  the client area, and any local monthly-plan pricing.