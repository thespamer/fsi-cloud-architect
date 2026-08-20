# Cloud Enablement — Platform as a Product

Most of this role's responsibilities are enablement, not design: make core
infrastructure services consumable in cloud, drive adoption, increase migration
velocity, foster innovation, deliver business value efficiently. This file is how
that work is actually done.

The core idea: **the platform is a product, engineering teams are its customers,
and adoption is the measure of success.** Architecture nobody adopts is a
rounding error.

---

## 1. Enterprise Cloud Programmes

A cloud programme fails for organisational reasons far more often than technical
ones. The structure that works:

**Name the business outcome, not the technology.** "Migrate 40% of the estate to
GCP" is not an outcome. "Reduce time-to-provision a new analytics environment
from 6 weeks to 1 day for the research business unit" is. The second one gets
funded and the first one gets cut.

**Sequence by dependency, not by enthusiasm.** Landing zone and guardrails →
core infrastructure services made consumable → golden paths → workload
migration. Teams migrated ahead of the platform generate technical debt the
platform team then owns.

**Fund the platform separately from the migrations.** If platform work is charged
to migration projects, it gets cut when a migration slips, and every subsequent
migration is slower.

**Publish a roadmap engineering teams can plan against.** Teams route around a
platform whose availability dates they cannot trust.

**Capital expense budgeting** is named explicitly in the role definition. Every programme
carries: one-off migration cost, steady-state run cost, the on-prem cost being
retired (and *when* it can actually be retired — usually later than planned,
because of trailing dependencies), and the payback period. Be honest about
double-running cost; understating it is the fastest way to lose credibility.

---

## 2. Making Core Infrastructure Services Consumable

The role definition's phrasing is precise: *"Ensures core FactSet Infrastructure
services are available in the cloud and easily consumable by FactSet engineering
teams."*

Two failure modes, both common:

- **Available but not consumable.** The service exists in cloud, but using it
  requires a ticket, tribal knowledge, or three teams. Teams build their own
  instead.
- **Consumable but not compliant.** The easy path is the non-compliant one, so
  either teams are non-compliant or they are slow.

**The gap inventory.** Start here. List every core infrastructure service the
on-prem estate provides — DNS, identity, secrets, certificates, artefact
repositories, logging, monitoring, backup, file services, scheduling, service
discovery, network access. For each: is it available in GCP? in AWS? is it
self-service? is it compliant by default? That table is the enablement backlog,
and it is more valuable than any architecture diagram.

**The consumability bar.** A service is consumable when a team can:

1. Discover it without asking a person
2. Provision it via IaC in under an hour, with no ticket
3. Get a working example that runs
4. Understand its cost before committing
5. Know who to page when it breaks

Anything short of all five will be routed around.

---

## 3. Golden Paths

A golden path is the **paved, opinionated, compliant-by-construction** route to
doing a common thing. It is the single highest-leverage artefact a platform
architect produces.

**The candidates, for a GCP-first house with AWS:**

| Golden path | What it provisions |
| --- | --- |
| **New service on GKE** | Namespace, workload identity, network policy, ingress via ILB/ALB, secrets binding, logging and monitoring wired, cost labels, CI/CD scaffold |
| **New service on Cloud Run** | Service, service account, PSC/VPC connector, secrets, observability, custom domain, IAM |
| **New data pipeline** | Storage with CMEK and lifecycle, IAM, orchestration, lineage, retention where regulated |
| **New AI workload** | Private endpoint, perimeter enrolment, package mirror access, eval hook, audit logging — see `08-genai-ml-platform.md` |
| **New environment for a business unit** | Project/account, network attachment, guardrails, budget, break-glass |
| **Hybrid connectivity for a workload** | Subnet, route advertisement, DNS, firewall policy — see `02-private-connectivity.md` |

**Rules for golden paths:**

- **Compliant by construction.** Encryption, logging, tagging, network policy and
  retention come with the path, not as a later review. This is how security
  posture scales — "work with the security organisation" is best
  discharged by building their controls into the paths.
- **Opinionated.** One good way, not five configurable ways. Configurability is
  the enemy of a paved road.
- **Escape hatch, registered.** Teams with a genuine reason to deviate can, and
  the deviation is recorded with a compensating control and an expiry date. A
  path with no escape hatch gets bypassed silently, which is worse.
- **Versioned and maintained.** A golden path that has not been updated in a year
  is a trap.
- **Measured.** Track what fraction of new services use the path. If it is
  falling, the path is wrong — find out why rather than mandating it.

---

## 4. Migration Velocity

The role definition: *"Increase velocity of cloud migration and digital
transformation by helping engineering teams adopt DevOps, Infrastructure as Code,
and automated release processes."*

**Diagnose before prescribing.** Stalled migrations usually stall for one of a
small number of reasons. Ask which:

| Blocker | Intervention |
| --- | --- |
| No landing zone / no place to land | Platform work — sequence it first |
| Team lacks cloud skill | Embedded engineer for one migration, not a training course |
| Dependency on an on-prem service not available in cloud | Enablement backlog item — this is the gap inventory |
| Licensing or vendor constraint | Commercial, not technical — escalate early, they take months |
| Manual release process nobody trusts | CI/CD uplift before migration, not after |
| Fear of the unknown / no rollback | A tested rollback and a small first slice |
| Genuine architectural incompatibility | Rebuild decision — make it explicitly, with a cost |

**The migration pattern ladder**, with honest framing:

| Pattern | When it is right | The trap |
| --- | --- | --- |
| **Retire** | The workload has no users | Nobody checks; everything migrates |
| **Retain** | Stable, amortised, no growth | Used as an excuse to avoid hard cases |
| **Rehost** (lift-and-shift) | Time pressure, datacentre exit, low-value workload | Delivers zero velocity gain and often costs more than on-prem. Fine as a *step*, bad as a destination |
| **Replatform** | Managed database, container runtime, managed queue — real gain, contained risk | Usually the best value; under-used because it is unglamorous |
| **Refactor** | High-value, high-change workloads where cloud-native genuinely pays | Expensive; do it for the top of the estate, not the middle |
| **Replace** (SaaS) | Commodity capability | Data residency and exit obligations still apply |

**Embed, do not advise.** The fastest way to level up a team's cloud knowledge is
to put an architect in the team for one migration, building it with them. The
knowledge transfer from a document is close to zero; from a shared build it is
close to complete. This scales worse and works better — accept the trade.

**Reference implementations beat standards documents.** A working repository a
team can copy transfers more than a wiki page ever will.

---

## 5. Fostering Innovation Without Losing Control

The role asks the architect to foster a culture of innovation and encourage
colleagues to think differently. In a regulated firm that has a specific shape:

- **A sandbox that is genuinely safe.** Disconnected from production networks,
  hard budget cap, automatic expiry, no regulated data. Then let people try
  things without a review. The absence of a safe place to experiment is why
  experiments happen in production.
- **Time-boxed spikes with a written outcome.** Two weeks, a decision, a short
  write-up either way. "We tried it and it did not work, here is why" is a
  valuable artefact and should be treated as one.
- **Make the new thing easy to try and hard to accidentally productionise.**
  Preview features are fine in a sandbox and are a design risk in production —
  the guardrails should encode that distinction, not a policy nobody reads.
- **Publish the decisions, including the rejected options.** An ADR archive is
  how an organisation stops re-litigating the same choice, and how new people
  learn what has already been tried.
- **Credit the teams.** An architecture function that takes credit for teams'
  work stops receiving their problems, which is the end of its usefulness.

---

## 6. Measuring Enablement

*"Focuses on providing efficient business value; ensuring programs are delivered
as efficiently as possible."* Efficiency claims need numbers.

**Adoption metrics** (is the platform being used?)

- Share of new services provisioned via a golden path
- Number of teams self-serving without a platform ticket
- Time from request to a working environment — measured, not estimated
- Gap-inventory items closed

**Velocity metrics** (is the platform making teams faster?)

- Lead time from commit to production, before and after migration
- Deployment frequency per team
- Change failure rate and time to restore
- Migration throughput: workloads per quarter, and the trend

**Efficiency metrics** (is it worth it?)

- Cost per unit of business value — per environment, per million messages, per
  client API call. See `05-landing-zone-iac.md` §6
- Platform cost as a share of total cloud spend
- Toil: platform tickets per engineer per month, trending down

**Posture metrics** (is it safe?)

- Share of estate covered by guardrails
- Open exceptions and their age
- Tier 1 systems with a passing DR test in period — see `09-ha-dr-patterns.md`

**Pick five and publish them monthly.** A metric nobody sees changes nothing. A
metric that goes the wrong way and is discussed openly builds more credibility
than a dashboard of green.

---

## 7. Working Across the Organisation

**Strategic Business Units** — they own outcomes and budgets. Speak in their
terms: time to market, cost per client, risk. Bring them options with numbers,
not architecture.

**Engineering teams** — they are the platform's users. Their complaints are
product feedback. The most useful hour in the week is often the one spent
watching a team try to use something you built.

**Security** — partner, not gate. The best outcome is their controls embedded in
golden paths so compliance is automatic. Involve them at design time; a security
review that first sees a design at the end will reject it, correctly.

**Other Platform Infrastructure teams** — networking, identity, storage,
observability. Adoption of cloud services depends on their services being
consumable. Their roadmaps are your dependencies; treat them as such.

**Finance** — capex budgeting and business cases. A trusted cost model is
political capital. Be the person whose numbers hold up.

**On-call** — the role includes periodic on-call and occasional weekend work. Being in
the rotation is not overhead; it is the feedback loop that keeps the architecture
honest.

---

## 8. Anti-Patterns

| Anti-pattern | What goes wrong |
| --- | --- |
| Standards published without a paved path to comply | Teams comply slowly or not at all; the standard becomes fiction |
| Review board as the primary control | Scales badly, arrives too late, and makes architecture a tax |
| Platform funded from migration budgets | Platform work is cut first, every subsequent migration is slower |
| Lift-and-shift declared as the destination | No velocity gain, often higher cost, and the debt is now yours |
| Golden path with fifty configuration options | Not a path; just a wrapper |
| Training courses instead of embedded engineers | Near-zero knowledge transfer |
| Adoption mandated rather than earned | Compliance theatre; teams build shadow platforms |
| Architecture function that does not operate anything | Designs drift from operational reality; loses credibility with on-call |
| Metrics that are all green | Nobody believes them, including you |
