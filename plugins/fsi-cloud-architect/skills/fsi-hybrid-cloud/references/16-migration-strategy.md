# Migration Strategy and Hybrid Deployment Options

This file covers two things that are related but distinct: **how to decide
the migration approach for an application** (the 6 Rs, wave planning), and
**where a workload can legitimately run outside a core cloud region**
(Outposts, Local Zones, distributed-cloud/bare-metal options) for reasons
other than the extreme low-latency case already covered in
`03-low-latency-market-data.md`. It also deepens DR testing and chaos
engineering, which `09-ha-dr-patterns.md` §6 names as a deliverable but does
not detail.

---

## 1. The 6 Rs

The standard decision set for what happens to an individual application
during a migration. Apply it per application, not once for the whole
estate — a thousand-application migration is a thousand small decisions
using the same rubric, not one big decision.

| R | What it means | Right when | Cost / risk |
| --- | --- | --- | --- |
| **Rehost** ("lift and shift") | Move as-is, VM for VM | Time pressure, TSA/contract deadline, or the application is not worth further investment yet | Lowest cost, fastest, but carries the source architecture's inefficiencies into the target |
| **Replatform** ("lift, tinker and shift") | Move with targeted changes — managed database instead of self-hosted, managed Kubernetes instead of self-managed | The application is worth some investment but a full rebuild is not justified | Moderate cost; the most common right answer for a mature application with life left in it |
| **Repurchase** | Replace with a SaaS or managed equivalent | The application is a commodity capability (CRM, ticketing, generic infra) not a differentiator | Often the cheapest long-run option; procurement and data-migration risk, not technical risk |
| **Refactor / rearchitect** | Rebuild to be cloud-native | The application is strategic and the current architecture is the actual constraint on the business | Highest cost and time; reserve for the minority that justifies it |
| **Retire** | Decommission | Usage data shows the application is no longer needed | Negative cost — the best answer when it applies, and under-used because nobody wants to be the one to say it |
| **Retain** | Leave in place for now | A named blocking dependency exists (licensing, a hardware dependency, an active vendor negotiation) — see §3 for cases where "retain" is a durable answer, not a deferral | Zero migration cost now, but is a decision to revisit, not a decision to forget |

**The rubric that resolves most disagreements:** business criticality on one
axis, technical complexity/debt on the other. High criticality, low
complexity → replatform confidently. Low criticality, high complexity →
retire or rehost and stop thinking about it. High criticality, high
complexity is where the refactor investment actually belongs — and where
people are tempted to refactor things that do not need it, because it is the
more interesting engineering problem.

**Do not let "retire" get skipped.** In most estates that have not
inventoried usage recently, 10–20% of applications have negligible active
usage. Retire is the highest-leverage item on this list and the one most
often not seriously considered because nobody owns the decision to turn
something off.

---

## 2. Migration Wave Planning

### Discovery before waves

You cannot wave-plan what you have not inventoried. Minimum viable
discovery: application list, owner, dependency map (what calls it, what it
calls), data volume and classification, current utilisation, and a 6-R
recommendation per application. Automated discovery tooling accelerates
this; it does not replace owner confirmation — automated dependency
mapping reliably under-detects batch and cron-triggered dependencies.

### Sequencing rules

1. **Move dependencies before or with their dependents, never after.** A
   dependency mapping exercise exists specifically to prevent moving an
   application whose database has not moved yet.
2. **Start with a wave that proves the pattern, not the hardest
   application.** The first wave's purpose is validating the migration
   factory (tooling, runbook, rollback path) on lower-risk applications. Save
   the genuinely hard cases for when the process is proven.
3. **Group by shared dependency, not by business unit.** Applications
   sharing a database, an identity system or a network segment usually need
   to move together regardless of who owns them organisationally.
4. **Size waves to what can be verified, not what can be executed.**
   Migration execution scales with tooling; verification scales with people
   reading dashboards and confirming correctness. Do not let wave size outrun
   verification capacity.
5. **Build the rollback path before the wave, not during an incident.** Every
   wave needs a defined and tested way back to the source state within a
   stated time budget.

### The migration factory model

For estates beyond a handful of applications, treat migration as a factory,
not a series of bespoke projects:

- **A standard toolchain** per pattern (rehost tooling, database migration
  tooling, container replatforming pipeline) applied repeatedly rather than
  reinvented per application.
- **A runbook template** (see `examples/migration-plan-template.md`) filled
  in per application, not rewritten from scratch.
- **A cutover checklist** that is the same for every application in a given
  R category, so cutover quality does not depend on which engineer is
  running it that week.
- **Throughput tracking** — applications migrated per week/month against
  target, with the blockers that are actually slowing it down. Migration
  velocity is one of the four enterprise strategies named in
  `00-role-context.md` §2, and this is how it is measured, not asserted.

---

## 3. Hybrid Deployment Options Beyond Core Regions

`03-low-latency-market-data.md` §10–§12 covers bare metal, colocation and
proximity hardware for the extreme low-latency case. The same class of
product — infrastructure that runs on or very near customer premises but is
managed as an extension of the public cloud — also solves problems that have
nothing to do with microsecond latency. Worth a separate look so the
decision is not made only through a latency lens.

| Product family | What it is | Reach for it when the driver is |
| --- | --- | --- |
| **AWS Outposts / GCP Distributed Cloud (hosted or edge)** | Cloud-managed racks physically located in the customer's own data centre or a colocation facility | Data residency requiring the data to remain on-premises; a facility that cannot yet fully migrate but wants a consistent cloud operating model; local processing with intermittent connectivity to the region |
| **AWS Local Zones** | Provider-operated infrastructure in a metro area, closer to end users than the nearest full region | Moderate latency improvement for user-facing applications (tens of milliseconds matters, microseconds do not) without the operational burden of owning hardware — a materially different case from HFT placement in `03-low-latency-market-data.md` §3 |
| **AWS Wavelength** | Compute embedded in telecom provider networks | Mobile/edge applications where the telecom path itself is the latency driver — a narrow case, name the actual requirement before proposing it |
| **GCP / AWS bare metal (as covered in `03-low-latency-market-data.md` §10)** | Dedicated physical hardware, cloud-adjacent or cloud-hosted | Licensing that requires dedicated hardware, or workloads with a hardware dependency the standard instance catalogue does not meet — not only the low-latency case |

**The question to ask before proposing any of these:** is the actual
requirement latency (go to `03-low-latency-market-data.md`), data residency
(go to `04-security-compliance-fsi.md` §4), or an unwillingness to fully
migrate that should be examined rather than accommodated (go to §1 above and
ask honestly whether this is "retain" with a real reason or "retain" by
default). Each of these products is the right answer to exactly one of
those questions and an expensive way to avoid answering it to the other two.

---

## 4. DR Testing and Chaos Engineering

`09-ha-dr-patterns.md` §6 names automated DR testing and chaos engineering
as required deliverables. This is the detail on how to actually run that
programme.

### The maturity ladder

1. **Documented, untested runbook.** The starting point for most estates,
   and worth almost nothing as evidence of resilience.
2. **Scheduled, non-disruptive validation.** Fail over to standby, verify
   health, fail back — in a window, on a cadence, with the result recorded.
   This is the minimum bar for a Tier 1 or Tier 2 system.
3. **Dependency fault injection in non-production.** Kill the thing that
   actually breaks DR in practice — see `09-ha-dr-patterns.md` §4 (DNS,
   identity, secrets, registry) — and confirm the application's behaviour
   matches the design assumption, not just that a document says it should.
4. **Scenario-based game days**, including severe-but-plausible combined
   failures, per DORA's expectation. Rotate scenarios; do not always test the
   same one.
5. **Controlled production chaos**, scoped and reversible, for organisations
   that have earned it through the earlier stages. Do not start here in a
   financial firm.

### Tooling notes

- **AWS Fault Injection Service (FIS)** provides managed fault injection
  (instance termination, AZ network disruption, API throttling simulation)
  integrated with CloudWatch alarms as a stop condition.
- **Google Cloud** does not offer a first-party equivalent at the same
  breadth as of this writing; teams typically compose fault injection from
  Kubernetes-native tooling (for GKE workloads) plus targeted scripted
  failure injection (killing instances, revoking IAM bindings temporarily in
  a controlled test project, simulating zone failure by cordoning nodes).
  Verify current first-party tooling before asserting a gap — this is an
  area that moves.
- **Chaos engineering principles apply regardless of tooling:** start with a
  hypothesis ("the application survives losing its DNS resolver"), inject
  the smallest fault that tests it, define the stop condition before
  starting, and run in non-production until the organisation has evidence to
  justify production scope.

### What a genuine DR testing programme produces

- A measured RTO and RPO per test run, not just a target.
- A trend line — is measured performance improving, stable, or degrading as
  the estate changes underneath it.
- A record an auditor or regulator can read without a translation layer:
  system, tier, target, last test date, measured result, pass/fail.

This is the same dashboard `09-ha-dr-patterns.md` §6 asks for — this section
is what feeds it with real data instead of a schedule that says "quarterly"
and a folder that has not been opened.

---

## 5. Anti-Patterns

- **Migrating an application without its dependency map**, discovering
  mid-cutover that something else still needs the source environment.
- **Treating the 6 Rs as a one-time exercise.** An application classified
  "retain" eighteen months ago with no re-evaluation is a decision nobody is
  actually making anymore.
- **Reaching for Outposts/Local Zones/bare metal because "we're not ready to
  migrate" rather than because of a named residency, latency or hardware
  requirement.** This is the most expensive way to defer a decision.
- **Running the first migration wave against the hardest application** to
  "get it out of the way," and burning the organisation's confidence in the
  programme before the tooling is proven.
- **A DR testing programme that only ever tests the happy path** — the
  primary failure scenario, never the dependency failures that actually
  cause outages in practice.
- **Sizing wave throughput to migration tooling capacity while verification
  capacity silently becomes the actual bottleneck**, producing a backlog of
  unverified "migrated" applications.

---

## 6. Review Questions

1. For this application: which of the 6 Rs, and what evidence supports it —
   utilisation data, criticality, technical debt — rather than default
   inertia?
2. Has "retire" been seriously evaluated using actual usage data, not
   assumed away?
3. Is there a dependency map confirming what must move before, or with,
   this application?
4. What proves the migration factory (tooling, runbook, rollback) before the
   hardest applications are attempted?
5. If this design proposes Outposts, Local Zones, Wavelength or bare metal:
   is the driver latency, residency, or hardware — named explicitly — or is
   it an unexamined unwillingness to migrate?
6. What tier of DR testing maturity (§4) does this system currently sit at,
   and what is the plan to move up one level?
7. When was the DR runbook for this system last tested, and what was the
   measured RTO/RPO against the target?
8. Does the chaos/fault-injection scope match the organisation's
   demonstrated maturity, or does it assume a level of confidence not yet
   earned?
