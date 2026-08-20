# High Availability and Disaster Recovery

The role definition asks for two things: **input on HA/DR for cloud services**, and
**processes and tooling that help engineering teams implement HA/DR themselves**.
The second is the harder and more valuable one. A document telling teams to be
resilient changes nothing; a module and a test that make resilience the default
changes everything.

---

## 1. Tier Before You Design

Do not have the HA/DR conversation per application. Have it once, publish tiers,
and let teams self-classify against a rubric that a non-architect can apply.

A workable distribution — roughly matching Google's own guidance on how
enterprise estates fall out:

| Tier | Share of estate | RTO | RPO | Failure scope survived |
| --- | --- | --- | --- | --- |
| **Tier 1** — global, client-facing, revenue-bearing | ~5% | near zero | zero | Regional outage |
| **Tier 2** — regional business applications | ~35% | 15 min – 1 hr | minutes | Zonal outage, regional with manual failover |
| **Tier 3** — internal systems | ~60% | 1 – 12 hr | hours | Zonal outage; restore from backup for regional |

**Multi-region outage** is generally accepted as a residual risk. Say so
explicitly rather than leaving it implied — under DORA, the accepted risk needs
to be a documented decision.

**The rubric matters more than the tiers.** Give teams three or four yes/no
questions that land them in a tier: does an outage stop client-facing revenue;
is there a regulatory availability obligation; can the business operate manually
for a day; is data loss recoverable from an upstream source. Ambiguity here
becomes every team claiming Tier 1.

---

## 2. RTO and RPO Drive the Pattern, Not the Reverse

| Pattern | RTO | RPO | Cost | Use for |
| --- | --- | --- | --- | --- |
| **Backup and restore** | Hours–days | Hours | Lowest | Tier 3 |
| **Cold standby** | Hours | Minutes–hours | Low | Tier 3, larger systems |
| **Warm standby** (scaled-down replica, scale up on failover) | 15 min – 1 hr | Minutes | Medium | Tier 2 — the most common right answer |
| **Hot standby / active-active** | Near zero | Near zero | Highest | Tier 1 only |

Two rules that resolve most arguments:

1. **RPO of zero requires synchronous replication**, which restricts you to
   products that offer it and imposes a latency cost. Anything else is an
   asynchronous pattern with a non-zero RPO, however small. Teams asking for
   "zero data loss" usually mean "small data loss" — make them say the number.
2. **RTO near zero requires continuously running standby capacity.** That is
   expensive. Most applications should target 1–24 hour RTO with warm standby and
   automated scale-up. Reserve hot standby for the ~5%.

---

## 3. Service Capability — What Handles What

### Google Cloud

| Failure scope | Handled automatically by | Needs you to compose it |
| --- | --- | --- |
| **Zone** | GKE regional clusters, Cloud SQL HA configuration, Spanner, Cloud Storage, Cloud Load Balancing | Compute Engine (zonal by nature) — use MIGs across zones behind a load balancer |
| **Region** | Spanner multi-region, multi-region Cloud Storage | GKE multi-region (you run the clusters), Cloud Load Balancing with manual failover, most regional services — orchestrate failover yourself, typically via DNS or LB reconfiguration |
| **Limited DR capability** | — | Compute Engine (zonal), Dataflow (stateless but must restart), BigQuery (regional; no automatic multi-region replication) |

### AWS

| Failure scope | Handled by | Needs composition |
| --- | --- | --- |
| **AZ** | Multi-AZ RDS/Aurora, ELB across AZs, S3, DynamoDB | EC2 (use ASGs across AZs), self-managed stateful services |
| **Region** | S3 Cross-Region Replication, Aurora Global Database, DynamoDB Global Tables, Route 53 health-check failover | Everything else — orchestrate it |

### The rule that catches people

**Regional products survive zone loss. They do not survive region loss.** A
"highly available" Cloud SQL HA instance or Multi-AZ RDS is a *zonal* resilience
control. If the design claims regional resilience, point at the mechanism that
provides it.

---

## 4. The Dependency Trap

The thing that actually breaks DR is not the application — it is what the
application needs in order to start.

Enumerate and test these for every Tier 1 and Tier 2 system:

- **DNS** — can names resolve in the DR region? Are resolver endpoints there?
- **Identity** — is the IdP reachable? Are workload identities scoped to a region
  or account that survives?
- **Secrets** — replicated to the DR region, or a single-region dependency?
- **Container images and artefacts** — is Artifact Registry / ECR replicated, or
  will the DR region try to pull from a dead region?
- **Configuration** — where does it live, and does that survive?
- **The hybrid circuits** — does the DR region have its own private connectivity,
  or does it reach on-prem through the failed region?
- **CI/CD** — can you deploy a fix during the event?
- **Management plane** — Google's guidance is explicit: avoid depending on
  management-plane operations during critical business processes. A failover that
  requires creating new resources may fail exactly when the control plane is
  degraded.

**Design consequence:** pre-provision the DR path rather than creating it during
the event. Warm standby exists partly to avoid control-plane dependency at the
worst moment.

---

## 5. Data Replication Choices

| Choice | RPO | Cost | Note |
| --- | --- | --- | --- |
| Synchronous, multi-zone | 0 | Latency cost | Zone resilience only, unless the product is genuinely multi-region synchronous |
| Synchronous, multi-region | 0 | High latency cost | Spanner multi-region is the clean example; most systems cannot afford the write latency |
| Asynchronous, continuous | Seconds–minutes | Moderate | The usual Tier 1/2 answer |
| Scheduled snapshot/backup | Hours | Low | Tier 3 |

For **immutable/regulated records** (see `04-security-compliance-fsi.md` §2),
verify that replication **preserves the retention lock**. A replica without the
lock is not a compliant copy, and discovering that during an audit is expensive.

**Test the restore, not the backup.** A backup job that succeeds and a restore
that works are different facts. Annual restore test with documented output,
minimum.

---

## 6. Processes and Tooling — The Actual Deliverable

This is what the role is asking for. Ship these, not a policy document.

**1. A tier rubric and a registry.** Self-service classification, recorded in a
queryable place, tied to the workload's tags/labels. If you cannot list every
Tier 1 system in one query, you do not have a DR programme.

**2. Terraform modules that implement each tier.** A team choosing Tier 2 gets a
module that provisions the warm standby, the replication, the health checks and
the failover mechanism. The tier becomes a variable, not a design exercise.

**3. A failover runbook generator.** From the module's outputs, generate the
runbook — the actual commands, the order, the verification steps. Hand-written
runbooks rot; generated ones track the infrastructure.

**4. Automated DR testing in a pipeline.** Scheduled, non-disruptive where
possible (failover to standby, verify, fail back), disruptive on a slower cadence
in a controlled window. Record the measured RTO and RPO per run.

**5. A dashboard of measured versus target.** Per system: target RTO/RPO, last
test date, measured result, pass/fail. This is the artefact that survives contact
with an auditor, a regulator and a board.

**6. Game days.** Scenario-based exercises including severe-but-plausible
disruption, as DORA expects. Rotate the scenarios; include dependency failures
(DNS, IdP, registry) not just "the region is gone".

**7. Chaos engineering, scoped.** Start with dependency failure injection in
non-production. Do not start with production chaos in a financial firm — earn it.

---

## 7. Cost Discipline in DR

DR is where cost quietly doubles. Control it deliberately.

- **Warm standby scaled to a fraction** of production, with autoscaling and
  pre-warmed capacity reservations for the failover, is usually far cheaper than
  a full hot standby and meets a 15–60 minute RTO.
- **Pilot light** — data replicated continuously, compute defined but not running
  — is the cheapest pattern that still avoids a from-scratch rebuild.
- **Tier honestly.** The single biggest DR cost saving in most estates is
  reclassifying systems that were labelled Tier 1 by assertion.
- **Storage lifecycle in the DR region** — replicated data does not all need the
  same storage class as production.
- **Test cost is not waste.** Budget it explicitly, or testing will be the first
  thing cut and the capability will be fictional.

---

## 8. Review Questions

Use these when reviewing someone's HA/DR design.

1. What tier, and against which rubric answer? Who agreed it?
2. Which specific failure scope does this survive — zone, region, or both? Name
   the mechanism.
3. Is the claimed RPO achievable with the replication chosen? Synchronous or not?
4. Has the failover been tested? When? What was the measured RTO?
5. What does the application need in order to start, and does all of it exist in
   the DR region — DNS, identity, secrets, images, config, connectivity?
6. Does failover depend on the control plane creating resources during the event?
7. Does the DR region have its own hybrid connectivity, or does it route through
   the failed region?
8. Is there capacity in the surviving region for full production load, or only
   for the standby's current size?
9. For regulated records: does replication preserve the retention lock?
10. Is fail-*back* designed, or only failover? Most incidents end with a fail-back
    nobody planned.
