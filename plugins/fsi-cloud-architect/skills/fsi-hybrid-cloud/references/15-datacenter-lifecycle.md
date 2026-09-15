# Data Centre Lifecycle: Migration, TCO and Physical Capacity

This is the material that sits behind "should this workload be in our data
centre or in the cloud" and "how do we actually move the data." It is
deliberately separate from `01-hybrid-topology.md` and `02-private-connectivity.md`,
which assume the hybrid estate already exists and ask how it connects. This
file asks the question one step earlier: what belongs where, and what it
costs to change your mind.

---

## 1. The Three Decisions

Every workload sitting in a physical data centre is one of three cases.
Name which one before designing anything.

| Case | What it means | Default answer |
| --- | --- | --- |
| **Migrate** | Move to cloud; the data centre workload is a source, not a destination | Right for the majority of general-purpose compute and storage |
| **Stay** | Keep in the data centre by deliberate choice, not inertia | Right for a named subset — see §4 |
| **Repatriate** | Was in cloud, moving back to a data centre or colocation facility | Right occasionally, for a named and measured reason — see §4 |

**The failure mode in all three cases is the same: an undeclared default.**
An estate that has never had this conversation explicitly is an estate where
every workload is "stay" by omission, which is the most expensive of the
three options dressed up as the cheapest.

---

## 2. Large-Scale Data Migration

The network is rarely the constraint people expect it to be for compute and
configuration migration. It is very often the constraint for data.

### Offline vs online — do the arithmetic first

| Method | Rough rule of thumb | Use when |
| --- | --- | --- |
| **Online, over the private circuit** | A sustained 10 Gbps circuit moves roughly 100 TB/day at realistic utilisation; a 100 Gbps circuit roughly 1 PB/day | The volume finishes inside the migration window without starving production traffic on the same circuit |
| **Offline, physical appliance** | Bounded by shipping time plus appliance capacity, independent of circuit size | Volume and/or timeline make the online transfer arithmetic fail, or no adequate circuit exists yet |
| **Hybrid** | Bulk historical data offline; final delta online before cutover | The common answer for anything past the low tens of terabytes with a fixed cutover date |

Both clouds offer a physical transfer appliance product (Google Cloud's
Transfer Appliance family; AWS's Snow family, principally Snowball Edge for
most jobs). Treat capacity and lead time as **verify at the time**, not
"known" — appliance models, capacities and regional availability change
between design and execution. Do not quote a specific terabyte figure from
memory; check the current product page and log the number and date.

### Rules that hold regardless of method

- **Never plan a single-pass cutover for a data set with an active write
  path.** Do an initial bulk copy, then continuous delta sync (Storage
  Transfer Service, DataSync, database-native replication, or CDC tooling),
  then a short final cutover window. The bulk copy can take weeks; the
  cutover should take minutes to hours.
- **Checksum, do not assume.** Verify data integrity at the object or row
  level after transfer, not just a byte count match.
- **Model the migration's own network impact.** A migration saturating the
  same circuit as production hybrid traffic is an incident, not a project
  risk — see `02-private-connectivity.md` §3 for capacity sizing and treat
  the migration as a temporary consumer of that headroom, sized and
  scheduled explicitly.
- **Encrypt appliances and transfers.** Physical appliances carrying
  regulated data are a data-in-transit control, not an exception to one —
  see `04-security-compliance-fsi.md` §3.
- **Chain of custody matters for a physical appliance.** Log who packed it,
  the carrier, the tracking reference and who unpacked it at the receiving
  end. An auditor will ask.

---

## 3. TCO: Data Centre vs Cloud

The comparison people usually make — cloud monthly bill versus the data
centre's allocated hosting fee — undercounts both sides. Build the model
with the same categories on each side.

| Cost category | Data centre | Cloud |
| --- | --- | --- |
| **Compute/storage hardware** | Capex, depreciated over 3–5 years; refresh cycle is a project, not a line item | Opex, continuous; committed-use/reserved pricing trades flexibility for discount |
| **Facility** | Power, cooling, floor space, physical security — often allocated, rarely fully visible to the application owner | Bundled into the provider's price |
| **Network** | WAN circuits, cross-connects, ISP transit, hardware refresh | Egress, interconnect, load balancing — see `02-private-connectivity.md` §8 for the cloud side |
| **Licensing** | Often perpetual with maintenance, sometimes tied to physical socket/core counts | Often consumption-based; can be materially different for the same workload |
| **Staffing** | Facilities, hardware break/fix, physical logistics — a real headcount even if not billed to the application | Platform team cost is shared across the estate, not per application |
| **Idle and overprovisioned capacity** | Bought ahead of need in discrete increments (a rack, a chassis); the gap between purchased and used is a sunk cost | Elastic; the equivalent waste is unused reservations or oversized instances left running — visible in the bill if FinOps is doing its job |
| **Lead time cost** | Hardware procurement lead time forces capacity to be bought early, which is itself a cost | Near-zero marginal lead time, priced into the on-demand rate |
| **Exit cost** | Decommissioning, certified data destruction, contract termination — see §6 | Data egress for the eventual next move, contract termination if under commitment |

**Two things people get wrong in this model:**

1. **They compare cloud on-demand pricing to fully-depreciated data centre
   hardware.** That is the cheapest point in the data centre's cost curve
   compared against the most expensive point in the cloud's. Compare
   committed-use/reserved cloud pricing to the data centre's *current*
   replacement cost, not its book value.
2. **They leave facility and staffing cost out of the data centre side**
   because it is allocated overhead rather than a line item the application
   owner sees. It is real cost. Get the allocation, even approximately, or
   the comparison is not a comparison.

**Model 36 months, consistent with the rest of this skill's costing
convention** (`SKILL.md`, Core Positions). Show the crossover point if the
options cross — the answer to "is it cheaper" is very often "yes, after
month N," and that number is the actual decision input.

---

## 4. Repatriation — When It's the Right Call

Repatriation gets attention because a small number of visible cases (a few
published case studies of companies moving storage-heavy or otherwise
steady-state workloads back out of the public cloud) get generalised into
advice that does not hold for most estates. Treat it as narrow and evidenced,
not as a trend to follow.

**Repatriation is usually the right call for:**

- **Steady-state, high-volume, predictable workloads** where the
  elasticity that cloud sells is not being used — bulk storage or compute
  running at constant, high utilisation, 24/7, for years.
- **Workloads with egress-dominated cost** where the data rarely needs to
  leave the environment it sits in, so cloud's flexibility is being paid
  for and not consumed.
- **A single, well-understood application** with a stable resource profile,
  not a general-purpose estate.

**Repatriation is usually the wrong call when the actual problem is:**

- **An unoptimised cloud estate** (no committed-use discounts, oversized
  instances, no lifecycle policy on storage). Fix the FinOps discipline
  first — see `05-landing-zone-iac.md` §6 — before concluding the platform
  itself is the problem.
- **A one-time migration cost being mistaken for a recurring one.** Sunk
  migration cost is not evidence about ongoing run cost.
- **Nostalgia for capex predictability** without pricing the opportunity
  cost of the capital and the lead time it reintroduces.

**If repatriating, the exit checklist in §6 applies to the cloud side just
as it applies to a data centre exit** — this is a two-way lifecycle, not a
one-way migration.

---

## 5. Physical Capacity Planning

Worth understanding even for an organisation that is cloud-first, because
colocation and bare metal remain part of the named stack for specific
workloads (`03-low-latency-market-data.md` §10, §12) and because the
contrast is what makes cloud elasticity legible to a business audience that
has only ever seen the data centre model.

| Constraint | Data centre / colocation | Cloud |
| --- | --- | --- |
| **Power** | Purchased in discrete increments (kW per rack, committed via contract); a step function, not a dial | Abstracted away; the provider's problem, priced into the instance rate |
| **Cooling** | Rack density is capped by the facility's cooling design; high-density (GPU, some bare metal) needs a facility built for it | Abstracted away |
| **Physical space** | Fixed footprint; growth means a new cage, a new facility, or a renegotiation | Effectively unbounded from the tenant's perspective |
| **Hardware lead time** | Weeks to months for standard gear; longer for specialised hardware (high-end GPU, custom network gear) in constrained markets | Minutes, subject to regional capacity and quota |
| **Refresh cycle** | A discrete, funded project every 3–5 years | Continuous; the provider absorbs the hardware refresh |
| **PUE (Power Usage Effectiveness)** | Facility-dependent; older or smaller facilities run materially less efficient than modern hyperscale design | Hyperscale providers publish aggressive PUE figures and it is generally not a lever the tenant needs to manage |

**The planning consequence:** a data centre or colocation footprint has to
be sized ahead of demand, in discrete steps, against a lead time measured in
months. That is precisely the capacity-planning discipline organisations
adopt cloud to avoid. Where a workload has a genuine reason to sit on
physical infrastructure — latency, data residency, cost at sustained scale —
carry that capacity-planning discipline deliberately, do not inherit it by
accident from an estate nobody re-evaluated.

---

## 6. Data Centre Exit Runbook

The checklist for retiring a physical footprint (fully, or a partial
reduction), whether the driver is cloud migration or a colocation
consolidation.

1. **Inventory everything physically present**, not just what the CMDB
   claims — power draw, network drops, cross-connects, out-of-band
   management, physical security integrations. Undocumented hardware is
   common.
2. **Reconcile and terminate circuits and cross-connects** — coordinate with
   `02-private-connectivity.md` §7 (Operating the Circuits) so a
   decommission does not silently remove a resiliency leg still in use
   elsewhere.
3. **Certified data destruction** for any media not being physically
   relocated — get the certificate, retain it for the retention period that
   applies to whatever data the media held (see
   `04-security-compliance-fsi.md` §2).
4. **License reconciliation** — perpetual and socket/core-based licences
   often need explicit termination or transfer; failing to do this can leave
   an organisation paying maintenance on retired hardware indefinitely.
5. **Contract and lease exit** — colocation and facility contracts typically
   carry notice periods measured in months; work backwards from the desired
   exit date, not forwards from when the decision was made.
6. **Update DNS, monitoring, and CMDB** to remove the retired footprint —
   stale entries here are a recurring source of false alarms and, worse,
   false confidence that something still exists.
7. **Verify no dependency was missed** — a repeat of the M&A due-diligence
   discipline in `11-ma-cloud-integration.md` §1, run against your own
   estate: is there a single point of knowledge, an undocumented batch job,
   a forgotten DNS delegation, that still expects this facility to exist?
8. **Retain the decommission record** — what was destroyed, what was
   migrated, what was terminated, and when. This is the artefact an auditor
   asks for eighteen months later.

---

## 7. Cost Model Inputs Checklist

Use this when building the migrate/stay/repatriate business case in §3, so
the model is not quietly missing a category.

**Data centre side:** hardware capex and depreciation schedule, facility
allocation (power, cooling, space, physical security), WAN and cross-connect
cost, licensing (including maintenance), staffing allocation, refresh
project cost amortised, planned exit cost.

**Cloud side:** committed-use/reserved cost at realistic utilisation,
on-demand cost for burst, storage cost by class and lifecycle policy,
egress (in and cross-region, per `02-private-connectivity.md` §8), platform
team cost allocation, migration cost amortised over the same horizon as the
data centre's refresh cycle for a fair comparison.

**Both sides:** the crossover month, not just the 36-month total — see §3.

---

## 8. Review Questions

1. For this workload: migrate, stay, or repatriate — and what is the named
   reason, not just "that's where it already is"?
2. Does the TCO model include facility and staffing allocation on the data
   centre side, and committed-use pricing (not on-demand) on the cloud side?
3. For a migration: has the online-vs-offline arithmetic been done against
   the actual volume and the actual circuit or appliance capacity, verified
   at the time of the design, not assumed from memory?
4. Is there a continuous delta-sync plan for data with an active write path,
   or is this a single-pass cutover risking an extended outage window?
5. Has the migration's network impact been sized against existing hybrid
   circuit capacity and scheduled to avoid contention with production
   traffic?
6. For a repatriation case: is the driver a genuine steady-state cost
   mismatch, or an unoptimised cloud estate that should be fixed first?
7. Does the physical capacity plan (power, cooling, space, lead time) exist
   and get reviewed on a cadence, for any workload still on physical
   infrastructure?
8. If this facility or footprint were exited today, does the runbook in §6
   have a named owner for every step, including certified data destruction
   and licence reconciliation?
