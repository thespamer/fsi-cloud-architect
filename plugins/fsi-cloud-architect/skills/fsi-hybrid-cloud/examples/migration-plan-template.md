# Migration Plan: [Workload / Estate Name]

| Field | Value |
| --- | --- |
| Owner | |
| Date | YYYY-MM-DD |
| Enterprise strategy served | Digital Transformation / M&A / Investment Programme / GenAI Enablement |
| Migration pattern | Rehost / Replatform / Refactor / Retire / Retain — [see `references/11-ma-cloud-integration.md` §3 if this is an M&A integration] |

---

## 1. Current State

- **What runs today, and where.** [System inventory — link to it, don't paste it here if it's large.]
- **Known technical debt or constraint forcing this migration.** [No landing zone, missing skill, on-prem dependency not available in cloud, licensing constraint, untrusted release process, or genuine incompatibility — name the real one; see `references/10-cloud-enablement.md` §1.]
- **Overlapping address space?** [RFC1918 overlap is the default state, not the exception, when two estates combine — see `references/11-ma-cloud-integration.md` §4 for the renumber/isolate/NAT-bridge decision table.]

## 2. Target State

- **Landing zone / org structure this lands in.** [`references/05-landing-zone-iac.md`]
- **Golden path(s) this migration consumes**, rather than a bespoke build. [Name it — enablement outranks elegance.]
- **What "done" looks like, in one sentence per workload.**

## 3. Target Topology

```mermaid
graph LR
  %% Source estate -> target estate, with the transit/connectivity path
  %% named explicitly (NCC hub, TGW, Interconnect/Direct Connect circuit).
```

## 4. Migration Waves

Sequence workloads by risk and dependency, not alphabetically.

| Wave | Workloads | Dependencies that must land first | Target date | Rollback complexity |
| --- | --- | --- | --- | --- |
| 0 — Pilot | | | | Low |
| 1 | | | | |
| 2 | | | | |

## 5. Cutover Approach, Per Wave

- **Pattern:** [Big-bang / phased traffic shift / dual-run with reconciliation]
- **Traffic-shift mechanism:** [DNS weighted routing, LB backend swap, feature flag — name it]
- **Data migration and sync:** [One-time bulk / continuous replication / CDC — and how long divergence is tolerated]
- **Verification before calling it done:** [The specific test, not "smoke tested"]

## 6. Connect the Minimum

Two estates fully routed to each other doubles the blast radius on day one
(`references/11-ma-cloud-integration.md` §4 — this principle applies beyond
M&A; see also the anti-pattern entry in `references/01-hybrid-topology.md` §9).

- **Specific flows connected in this wave:** [Not "everything" — enumerate]
- **What is deliberately NOT connected yet, and why:**
- **NAT bridges in place, if any, with an expiry date and an owner:** [Permanent NAT breaks source-IP attribution and incident forensics — every bridge gets an expiry date]

## 7. Rollback Plan

Per wave, not just for the migration as a whole.

| Wave | Rollback trigger | Rollback mechanism | Rollback time | Data loss risk |
| --- | --- | --- | --- | --- |
| | | | | |

## 8. Cost

36-month view, with double-running cost stated honestly — this is usually
the fastest way to lose credibility if understated.

| Item | Current (annual) | During migration (peak double-run) | Target (annual) |
| --- | --- | --- | --- |
| Compute | | | |
| Storage | | | |
| Egress / data transfer | | | |
| Licensing | | | |
| **Total** | | | |

**When on-prem/legacy actually gets retired, and what that removes from the cost base:** [Be specific — "eventually" is not a decommission date.]

## 9. Identity, Guardrails and Compliance

- **Guardrails applied before workloads land, not retrofitted after:** [`references/04-security-compliance-fsi.md`]
- **Regulatory obligations that constrain sequencing or topology:** [Data residency, retention, exit strategy, concentration risk — `references/00-role-context.md`, and `12-pci-dss.md` / `13-open-finance-open-banking.md` / `14-banking-as-a-service.md` if applicable]

## 10. Risk Register

| Risk | Likelihood | Impact | Mitigation | Owner |
| --- | --- | --- | --- | --- |
| | | | | |

## 11. Validation and Sign-Off

- **Who signs off on each wave before the next starts:**
- **Metric that proves the migration worked**, per `references/10-cloud-enablement.md` §6 — not "no complaints," a number.

## References

- `references/NN-*.md` §N — [what it backs]
